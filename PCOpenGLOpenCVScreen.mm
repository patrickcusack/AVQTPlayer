//
//  PCOpenGLScreen.m
//  CAOpenGLLayerTest
//
//  Created by Patrick Cusack on 7/3/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#include <GL/glew.h>
#import "PCOpenGLOpenCVScreen.h"
#include <GLTools.h>
#include <GLShaderManager.h>
#include <GLMatrixStack.h>
#include <GLFrustum.h>
#include <GLGeometryTransform.h>
#include "ImageHelper.h"
#import <AppKit/NSImage.h>
#import "PCOpenGLDiffPixelBuffer.h"
#import <OpenCV2/opencv.hpp>

extern "C" {
#import "ShaderHelpers.h"
}


#define KTEXTURECOUNT 2
#define KTEXTUREA 0
#define KTEXTUREB 1

@interface PCOpenGLOpenCVScreen(){
	GLBatch screen;
    GLFrustum viewer;
    GLShaderManager shaderManager;
    GLMatrixStack projectionMatrix;
    GLMatrixStack modelViewMatrix;
    GLGeometryTransform transformer;
    GLuint textures[KTEXTURECOUNT];
    GLuint shaderProgram;
}

@end

@implementation PCOpenGLOpenCVScreen
@synthesize bufferA;
@synthesize bufferB;
@synthesize delegate;
@synthesize buffersA;
@synthesize buffersB;
@synthesize shouldSynchronize;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        GLenum err = glewInit();
        if (GLEW_OK != err){
            fprintf(stderr, "GLEW error:  %s\n", glewGetErrorString(err));
            return nil;
        }
        
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_TEXTURE_2D);
        
        shaderManager.InitializeStockShaders();
        viewer.SetOrthographic(-960./2.f, 960./2.f, -540./2.f, 540./2.f, -5.0f, 5.0f);
        projectionMatrix.LoadMatrix(viewer.GetProjectionMatrix());
        modelViewMatrix.LoadIdentity();
        transformer.SetMatrixStacks(modelViewMatrix, projectionMatrix);
        glGenTextures(KTEXTURECOUNT, textures);
        
        checkGlError("init");

        const char * nVertexShader = [[[NSBundle mainBundle] pathForResource:@"ShaderDemoOpenCV" ofType:@"vsh"] UTF8String];
        const char * nFragmentShader = [[[NSBundle mainBundle] pathForResource:@"ShaderDemoOpenCV" ofType:@"fsh"] UTF8String];
        shaderProgram = shaderManager.LoadShaderPairWithAttributes(nVertexShader, nFragmentShader, 2,
                                                                   GLT_ATTRIBUTE_VERTEX, "vVertex",
                                                                   GLT_ATTRIBUTE_TEXTURE0, "vTexCoord0");
        
        [self buildScreen];
        
        [self setDelegate:nil];
        [self setBuffersA:[NSMutableArray arrayWithCapacity:10]];
        [self setBuffersB:[NSMutableArray arrayWithCapacity:10]];
        [self setShouldSynchronize:NO];
    }
    return self;
}

- (void)dealloc{
    //delete textures
    [self setBuffersA:nil];
    [self setBuffersB:nil];
    [self setBufferA:nil];
    [self setBufferB:nil];
    [super dealloc];
}

- (void)buildScreen{
    screen.Begin(GL_TRIANGLE_STRIP, 4, 1);
    screen.MultiTexCoord2f(0, 0.0, 1.0);
    screen.Vertex3f(-950./2, -540/2, 0);
    screen.MultiTexCoord2f(0, 1.0, 1.0);
    screen.Vertex3f(950./2, -540/2, 0);
    screen.MultiTexCoord2f(0, 0.0, 0.0);
    screen.Vertex3f(-950./2, 540/2, 0);
    screen.MultiTexCoord2f(0, 1.0, 0.0);
    screen.Vertex3f(950./2, 540/2, 0);
    screen.End();
}

- (void)buildTestTextures{
    
    int width, height, maskComponents, maskFormat;
    
    GLubyte * data = (GLubyte*)malloc(6220800);
    FILE * file = fopen("/Users/patrickcusack/Documents/IMAGE_COMPARSISON_TESTS/demoPC copy/TestData/rgbDataFromProRes", "rb");
    (void)fread(data, sizeof(GLubyte), 6220800, file);
    
    //assign first texture
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 1920, 1080, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
    free(data);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    data = (GLubyte*)createDataForImage([[[NSBundle mainBundle] pathForResource:@"a" ofType:@"png"] UTF8String],
                                                      &width,
                                                      &height,
                                                      &maskComponents,
                                                      &maskFormat);
    
    //assign first texture
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREB]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, maskComponents, width, height, 0, maskFormat, GL_UNSIGNED_BYTE, data);
    free(data);
    
}


- (cv::Mat)matForPixelBuffer:(PCOpenGLDiffPixelBuffer*)pixelBuffer{

    cv::Mat img((int)[pixelBuffer height], (int)[pixelBuffer width], CV_MAKETYPE(CV_8U,(int)[pixelBuffer numberOfBytes]), [pixelBuffer data]);
    return img;
    
}


- (void)addBufferToBuffersA:(PCOpenGLDiffPixelBuffer*)buffer{
    [[self buffersA] insertObject:buffer atIndex:0];
    if ([[self buffersA] count] > 3) {
        [[self buffersA] removeLastObject];
    }
}

- (void)addBufferToBuffersB:(PCOpenGLDiffPixelBuffer*)buffer{
    [[self buffersB] insertObject:buffer atIndex:0];
    if ([[self buffersB] count] > 3) {
        [[self buffersB] removeLastObject];
    }
}


- (void)attachBuffers{
    
    if ([self shouldSynchronize] == YES) {
        
        PCOpenGLDiffPixelBuffer * nBufferA = [[self buffersA] firstObject];
        PCOpenGLDiffPixelBuffer * nBufferB = [[self buffersB] firstObject];
        
        NSUInteger currentAFrame = [nBufferA currentFrame];
        NSUInteger currentBFrame = [nBufferB currentFrame];
        
        if (currentAFrame == currentBFrame) {
            
            [self setBufferA:nBufferA];
            [self setBufferB:nBufferB];
        
        } else if (currentAFrame > currentBFrame){
            
            PCOpenGLDiffPixelBuffer * altBuffer = nil;
            
            for(PCOpenGLDiffPixelBuffer * buffer in [self buffersA]){
                if ([buffer currentFrame] == currentBFrame) {
                    altBuffer = buffer;
                    break;
                }
            }
            
            [self setBufferA:altBuffer];
            [self setBufferB:nBufferB];
            
        } else if (currentAFrame < currentBFrame){
            
            PCOpenGLDiffPixelBuffer * altBuffer = nil;
            
            for(PCOpenGLDiffPixelBuffer * buffer in [self buffersB]){
                if ([buffer currentFrame] == currentAFrame) {
                    altBuffer = buffer;
                    break;
                }
            }
            
            [self setBufferA:nBufferA];
            [self setBufferB:altBuffer];
            
        }
        
    }
    
    if (![self bufferA] || ![self bufferB]) {
        return;
    }
    
    if ([[self bufferA] hasBeenRead] == YES && [[self bufferB] hasBeenRead] == YES) {
        return;
    }
    
    cv::Mat imgA = [self matForPixelBuffer:[self bufferA]];
    cv::Mat imgB = [self matForPixelBuffer:[self bufferB]];
    cv::Mat imgCC;
    
    if (imgA.cols != imgB.cols || imgA.rows != imgB.rows) {
    
        cv::Mat resizedB;
        cv::resize(imgB, resizedB, cv::Size(1920,1080), 0, 0, cv::INTER_LINEAR);
        cv::absdiff(imgA, resizedB, imgCC);
        
        cv::Rect myROI(0, 3, 1920, 1080-6);
        cv::Mat imgDD = imgCC(myROI);

        double min, max;
        minMaxIdx(imgDD, &min, &max);
        
        cv::Scalar     mean;
        cv::Scalar     stddev;
        cv::meanStdDev ( imgDD, mean, stddev );
        double mean_pxl = mean.val[0];
        double stddev_pxl = stddev.val[0];
        
        NSString * info = [NSString stringWithFormat:@"max: %0.2f stdDev: %0.2f mean: %0.2f\n", max, mean_pxl, stddev_pxl];
        
        if ([self delegate]) {[[self delegate] screenHasInfoAvailable:info];}
        
        glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgDD.cols, imgDD.rows, 0, GL_BGRA, GL_UNSIGNED_BYTE, imgDD.data);
        
    } else {
        
        cv::absdiff(imgA, imgB, imgCC);
        
        double min, max;
        minMaxIdx(imgCC, &min, &max);
        
        cv::Scalar     mean;
        cv::Scalar     stddev;
        cv::meanStdDev ( imgCC, mean, stddev );
        double mean_pxl = mean.val[0];
        double stddev_pxl = stddev.val[0];
        
        NSString * info = [NSString stringWithFormat:@"max: %0.2f stdDev: %0.2f mean: %0.2f\n", max, mean_pxl, stddev_pxl];
        
        if ([self delegate]) {
            [[self delegate] screenHasInfoAvailable:info];
        }
        
        glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgCC.cols, imgCC.rows, 0, GL_BGRA, GL_UNSIGNED_BYTE, imgCC.data);
        
    }
    
    
    [[self bufferA] setHasBeenRead:YES];
    [[self bufferB] setHasBeenRead:YES];
}

- (void)draw{
    
    [self attachBuffers];
    
    GLfloat white[] = {1.0f, 1.0f, 1.0f, 1.0f};
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);		// clear the screen
    
    modelViewMatrix.LoadIdentity();
    
    //draw a white background
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Translate(0.0f, 0.0f, -2.0f);
    
    shaderManager.UseStockShader(GLT_SHADER_FLAT, transformer.GetModelViewProjectionMatrix(), white);
    screen.Draw();
    modelViewMatrix.PopMatrix();
    checkGlError("Drawing White Background");
    
    //draw a 2 two textured texture on a smaller screen
    modelViewMatrix.PushMatrix();
    modelViewMatrix.Translate(0.0f, 0.0f, -1.0f);
    modelViewMatrix.Scale(1.0, 1.0, 1.0);

    glUseProgram(shaderProgram);
    checkGlError("Using Shader Program");
    
    GLint iTransform, iTextureUnit0;
    
    iTransform = glGetUniformLocation(shaderProgram, "mvpMatrix");
    glUniformMatrix4fv(iTransform, 1, GL_FALSE, transformer.GetModelViewProjectionMatrix());
    
    iTextureUnit0 = glGetUniformLocation(shaderProgram, "textureUnit0");
    
    glUniform1i(iTextureUnit0, 0);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
    
    checkGlError("Loading uniforms");
    
    screen.Draw();
    
    checkGlError("Drawing");
    
    modelViewMatrix.PopMatrix();
    
}


@end
