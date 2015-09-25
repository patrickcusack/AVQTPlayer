//
//  IOSurfaceLayerView.m
//  IOSurfaceTest2
//
//  Created by Patrick Cusack on 5/7/15.
//

#import "IOSurfaceLayer.h"

@implementation IOSurfaceLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setAsynchronous:YES];
        [self setContentsGravity:kCAGravityResizeAspect];
        
        //This must be opaque
        CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 1);
        [self setBackgroundColor:black];
        CFRelease(black);
        
        _surfaceTexture = 0;
        
        [self setContentsScale:2.0];
    }
    return self;
}

- (void)dealloc{
    glDeleteTextures(1, &_surfaceTexture);
    [super dealloc];
}


-(CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask{
    NSOpenGLPixelFormatAttribute	mAttrs []	= {
        NSOpenGLPFAWindow,
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


- (void)_bindSurfaceToTexture: (IOSurfaceRef)aSurface inContext:(CGLContextObj)context{
    
    if (_surfaceTexture == 0) {
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glGenTextures(1, &_surfaceTexture);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
    }
    
    if (_surface && (_surface != aSurface)) {
        CFRelease(_surface);
    }
    
    if ((_surface = aSurface) != nil) {
        CGLContextObj   cgl_ctx = context;
        
        _texWidth	= (GLsizei)IOSurfaceGetWidth(_surface);
        _texHeight	= (GLsizei)IOSurfaceGetHeight(_surface);
        
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _surfaceTexture);
        CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, GL_RGB8,
                               _texWidth, _texHeight,
                               GL_YCBCR_422_APPLE, GL_UNSIGNED_SHORT_8_8_APPLE, _surface, 0);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
    }
}


- (void)setSurfaceID: (IOSurfaceID)anID
{
    if (anID) {
        _surfaceID = anID;
    }
}

- (void)setMovieSize:(NSSize)size{
    _movieSize = size;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx
                pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t
                displayTime:(const CVTimeStamp *)ts{
    return YES;
}

-(void)drawInCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat forLayerTime:(CFTimeInterval)timeInterval displayTime:(const CVTimeStamp *)timeStamp{
    
    // Set the current context to the one given to us.
    CGLSetCurrentContext(glContext);
    
    [self _bindSurfaceToTexture:IOSurfaceLookup(_surfaceID) inContext:glContext];
    
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
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (_surface) {
        GLfloat		texMatrix[16]	= {0};
        GLint		saveMatrixMode;
        
        // Reverses and normalizes the texture
        texMatrix[0]	= (GLfloat)_texWidth;
        texMatrix[5]	= -(GLfloat)_texHeight;
        texMatrix[10]	= 1.0;
        texMatrix[13]	= (GLfloat)_texHeight;
        texMatrix[15]	= 1.0;
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glLoadMatrixf(texMatrix);
        glMatrixMode(saveMatrixMode);
        
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _surfaceTexture);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    } else {
        glColor4f(0.4, 0.4, 0.4, 0.4);
    }
    
    //Draw textured quad
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glEnd();
    
    //Restore texturing settings
    if (_surface) {
        GLint		saveMatrixMode;
        
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPopMatrix();
        glMatrixMode(saveMatrixMode);
    }

    // Call super to finalize the drawing. By default all it does is call glFlush().
    [super drawInCGLContext:glContext pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];
    
}


@end
