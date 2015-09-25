//
//  VideoOutputLayer.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/8/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCOpenGLDiffLayer.h"
#import "PCOpenGLDiffPixelBuffer.h"
#import "PCOpenGLDiffShaderController.h"
#import "ShaderHelpers.h"

@interface PCOpenGLDiffLayer (){
    dispatch_queue_t _queue;
    PCOpenGLDiffShaderController * _shaderController;
    GLuint shaderProgram;
    
    GLuint VBO, VAO, EBO;
}
@end

@implementation PCOpenGLDiffLayer
@synthesize bufferA;
@synthesize bufferB;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setAsynchronous:YES];
        [self setContentsGravity:kCAGravityResizeAspect];
        
        //This must be opaque
        CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 0);
        [self setBackgroundColor:black];
        CFRelease(black);
        
        _queue = dispatch_queue_create(NULL, NULL);
        
        [self setContentsScale:2.0];
        
        _shaderController = nil;
        
    }
    return self;
}

- (void)dealloc{
    glDeleteTextures(1, &_textureA);
    glDeleteTextures(1, &_textureB);
    [super dealloc];
}

-(CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask{
    NSOpenGLPixelFormatAttribute	mAttrs []	= {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize,		(NSOpenGLPixelFormatAttribute)32,
        NSOpenGLPFAAlphaSize,		(NSOpenGLPixelFormatAttribute)8,
        NSOpenGLPFADepthSize,		(NSOpenGLPixelFormatAttribute)24,
        (NSOpenGLPixelFormatAttribute) 0
    };
    
    NSOpenGLPixelFormat * pxlFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: mAttrs];
    [pxlFormat autorelease];
    
    return [pxlFormat CGLPixelFormatObj];
}

- (void)setMovieSize:(NSSize)size{
    _movieSize = size;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx
                pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t
                displayTime:(const CVTimeStamp *)ts{
    
    CGLSetCurrentContext(ctx);
    
    if (!_shaderController) {
        _shaderController = [[PCOpenGLDiffShaderController alloc] init];
        shaderProgram = createProgramFromFiles("ShaderDemoAdd");
    }
    
    if (!_textureA) {
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &_textureA);
        glDisable(GL_TEXTURE_2D);
    }
    
    if (!_textureB) {
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &_textureB);
        glDisable(GL_TEXTURE_2D);
    }
    
    if (![self bufferA] || ![self bufferB]) {
        return NO;
    }
    
    return YES;
}

- (void)attachBuffers{
    [[self bufferA] setDataOnTexture:_textureA];
    [[self bufferB] setDataOnTexture:_textureB];
}

-(void)drawInCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat forLayerTime:(CFTimeInterval)timeInterval displayTime:(const CVTimeStamp *)timeStamp{
    
    // Set the current context to the one given to us.
    CGLSetCurrentContext(glContext);
    
    [self attachBuffers];
    _texWidth = (GLsizei)[[self bufferA] width];
    _texHeight = (GLsizei)[[self bufferA] height];
    
    CGRect backingBounds = [self bounds];
    backingBounds.size.width *= [self contentsScale];
    backingBounds.size.height *= [self contentsScale];
    
    glViewport(0, 0, backingBounds.size.width, backingBounds.size.height);
    
    float scaleX = backingBounds.size.width / _movieSize.width;
    float scaleY = backingBounds.size.height / _movieSize.height;
    float scaleN = 0.0;
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    if(scaleX > scaleY){
        scaleN = scaleX / scaleY;
        glOrtho(-1 * scaleN, 1 * scaleN, -1 , 1, -20., 20.);
    } else {
        scaleN = scaleY / scaleX;
        glOrtho(-1, 1, -1 * scaleN, 1* scaleN, -20., 20.);
    }
    
    //Clear background
    //    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if(_textureA && _textureB){
        
        GLfloat		texMatrix[16]	= {0};
        GLint		saveMatrixMode;
        
        // Reverses and normalizes the texture
        texMatrix[0]	= (GLfloat)_texWidth;
        texMatrix[5]	= (GLfloat)_texHeight;
        texMatrix[10]	= 1.0;
        texMatrix[13]	= 1.0;
        texMatrix[15]	= 1.0;
        
        //Configure shader paramters here
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glLoadMatrixf(texMatrix);
        glMatrixMode(saveMatrixMode);
        
        glEnable(GL_TEXTURE_2D);
        
        glUseProgram(shaderProgram);
        
        GLint iTransform, iTextureUnit0, iTextureUnit1;
        
        iTransform = glGetUniformLocation(shaderProgram, "mvpMatrix");
        glUniformMatrix4fv(iTransform, 1, GL_FALSE, texMatrix);
        
        iTextureUnit0 = glGetUniformLocation(shaderProgram, "textureUnit0");
        glUniform1i(iTextureUnit0, 0);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _textureA);
        
        iTextureUnit1 = glGetUniformLocation(shaderProgram, "textureUnit1");
        glUniform1i(iTextureUnit1, 1);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, _textureB);
        

    } else {
        glColor4f(0.4, 0.4, 0.4, 0.4);
    }
    
    //Draw textured quad
    glBegin(GL_QUADS);
    
//    glTexCoord2f(0.0f, 1.0f);
    glVertex3f(-1.0f,-1.0f, 1.0f);
    glTexCoord2f(0.0f, (GLfloat)_texHeight);
//    glVertex3f(-1.0 * (GLfloat)_texWidth/2,-1.0 * (GLfloat)_texHeight/2, 1.0f);
    
//    glTexCoord2f(1.0f, 1.0f);
    glVertex3f( 1.0f,-1.0f, 1.0f);
    glTexCoord2f((GLfloat)_texWidth, (GLfloat)_texHeight);
//    glVertex3f((GLfloat)_texWidth/2,-1.0 * (GLfloat)_texHeight/2, 1.0f);
    
//    glTexCoord2f(1.0f, 0.0f);
    glVertex3f( 1.0f, 1.0f, 1.0f);
    glTexCoord2f((GLfloat)_texWidth, 0.0f);
//    glVertex3f((GLfloat)_texWidth/2,(GLfloat)_texHeight/2, 1.0f);
    
//    glTexCoord2f(0.0f, 0.0f);
    glVertex3f(-1.0f, 1.0f, 1.0f);
    glTexCoord2f(0.0f, 0.0f);
//    glVertex3f(-1.0 * (GLfloat)_texWidth/2,(GLfloat)_texHeight/2, 1.0f);
    
    glEnd();
    
    
    //Restore texturing settings
    
    if (_textureA && _textureB) {
        GLint		saveMatrixMode;
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPopMatrix();
        glMatrixMode(saveMatrixMode);
    }
    
    
    // Call super to finalize the drawing. By default all it does is call glFlush().
    [super drawInCGLContext:glContext pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];
}




@end