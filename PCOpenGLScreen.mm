//
//  PCOpenGLScreen.m
//  CAOpenGLLayerTest
//
//  Created by Patrick Cusack on 7/3/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#include <GL/glew.h>
#import "PCOpenGLScreen.h"
#include <GLTools.h>
#include <GLShaderManager.h>
#include <GLMatrixStack.h>
#include <GLFrustum.h>
#include <GLGeometryTransform.h>
#include "ImageHelper.h"
#import <AppKit/NSImage.h>
#import "PCOpenGLDiffPixelBuffer.h"

extern "C" {
#import "ShaderHelpers.h"
}


#define KTEXTURECOUNT 2
#define KTEXTUREA 0
#define KTEXTUREB 1

@interface PCOpenGLScreen(){
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

@implementation PCOpenGLScreen
@synthesize bufferA;
@synthesize bufferB;
@synthesize scaleDifferenceMultiplier;
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

        const char * nVertexShader = [[[NSBundle mainBundle] pathForResource:@"ShaderDemoAdd" ofType:@"vsh"] UTF8String];
        const char * nFragmentShader = [[[NSBundle mainBundle] pathForResource:@"ShaderDemoAdd" ofType:@"fsh"] UTF8String];
        shaderProgram = shaderManager.LoadShaderPairWithAttributes(nVertexShader, nFragmentShader, 2,
                                                                   GLT_ATTRIBUTE_VERTEX, "vVertex",
                                                                   GLT_ATTRIBUTE_TEXTURE0, "vTexCoord0");
        
        [self buildScreen];
        [self setScaleDifferenceMultiplier:1.0];
        [self setBuffersA:[NSMutableArray arrayWithCapacity:10]];
        [self setBuffersB:[NSMutableArray arrayWithCapacity:10]];
        [self setShouldSynchronize:NO];
    }
    return self;
}

- (void)dealloc{
    //delete textures
    [self setBufferA:nil];
    [self setBufferB:nil];
    [self setBuffersA:nil];
    [self setBuffersB:nil];
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
    
    GLubyte *data = (GLubyte*)createDataForImage([[[NSBundle mainBundle] pathForResource:@"a" ofType:@"png"] UTF8String],
                                                      &width,
                                                      &height,
                                                      &maskComponents,
                                                      &maskFormat);
    
    //assign first texture
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, maskComponents, width, height, 0, maskFormat, GL_UNSIGNED_BYTE, data);
    free(data);
    
    
    data = (GLubyte*)malloc(6220800);
    FILE * file = fopen("/Users/patrickcusack/Documents/IMAGE_COMPARSISON_TESTS/demoPC copy/TestData/rgbDataFromProRes", "rb");
    (void)fread(data, sizeof(GLubyte), 6220800, file);
    
    //assign first texture
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREB]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 1920, 1080, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
    free(data);

    glBindTexture(GL_TEXTURE_2D, 0);
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
    
    if ([self shouldSynchronize] == NO) {
        if ([[self bufferA] hasBeenRead] == NO || [[self bufferB] hasBeenRead] == NO) {
            [[self bufferA] setDataOnTexture:textures[KTEXTUREA]];
            [[self bufferA] setHasBeenRead:YES];
            [[self bufferB] setDataOnTexture:textures[KTEXTUREB]];
            [[self bufferB] setHasBeenRead:YES];
        }
    } else {
        
        PCOpenGLDiffPixelBuffer * nBufferA = [[self buffersA] firstObject];
        PCOpenGLDiffPixelBuffer * nBufferB = [[self buffersB] firstObject];
        
        NSUInteger currentAFrame = [nBufferA currentFrame];
        NSUInteger currentBFrame = [nBufferB currentFrame];
        
        if (currentAFrame == currentBFrame) {
            
            [nBufferA setDataOnTexture:textures[KTEXTUREA]];
            [nBufferA setHasBeenRead:YES];
            [nBufferB setDataOnTexture:textures[KTEXTUREB]];
            [nBufferB setHasBeenRead:YES];
            
        } else if (currentAFrame > currentBFrame){
            
            PCOpenGLDiffPixelBuffer * altBuffer = nil;
            
            for(PCOpenGLDiffPixelBuffer * buffer in [self buffersA]){
                if ([buffer currentFrame] == currentBFrame) {
                    altBuffer = buffer;
                    break;
                }
            }
            
            [altBuffer setDataOnTexture:textures[KTEXTUREA]];
            [altBuffer setHasBeenRead:YES];
            [nBufferB setDataOnTexture:textures[KTEXTUREB]];
            [nBufferB setHasBeenRead:YES];

        } else if (currentAFrame < currentBFrame){
            
            PCOpenGLDiffPixelBuffer * altBuffer = nil;
            
            for(PCOpenGLDiffPixelBuffer * buffer in [self buffersB]){
                if ([buffer currentFrame] == currentAFrame) {
                    altBuffer = buffer;
                    break;
                }
            }
            
            [nBufferA setDataOnTexture:textures[KTEXTUREA]];
            [nBufferA setHasBeenRead:YES];
            [altBuffer setDataOnTexture:textures[KTEXTUREB]];
            [altBuffer setHasBeenRead:YES];
            
        }
        
    }

    
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
    
    GLint iTransform, iTextureUnit0, iTextureUnit1;
    GLfloat myscale;
    
    iTransform = glGetUniformLocation(shaderProgram, "mvpMatrix");
    glUniformMatrix4fv(iTransform, 1, GL_FALSE, transformer.GetModelViewProjectionMatrix());
    
    iTextureUnit0 = glGetUniformLocation(shaderProgram, "textureUnit0");
    iTextureUnit1 = glGetUniformLocation(shaderProgram, "textureUnit1");
    
    glUniform1i(iTextureUnit0, 0);
    glUniform1i(iTextureUnit1, 1);

    myscale = glGetUniformLocation(shaderProgram, "myscale");
    glUniform1f(myscale, [self scaleDifferenceMultiplier]);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREA]);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, textures[KTEXTUREB]);
    
    checkGlError("Loading uniforms");
    
    screen.Draw();
    
    checkGlError("Drawing");
    
    modelViewMatrix.PopMatrix();
    
}


@end
