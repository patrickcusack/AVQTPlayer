//
//  PCOpenGLDIffLayer.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/8/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl.h>
#import <AppKit/NSOpenGL.h>

@class PCOpenGLDiffPixelBuffer;

@interface PCOpenGLDiffLayer : CAOpenGLLayer {
    
    CGDirectDisplayID   _mainViewDisplayID;
    
    GLuint              _textureA;
    GLuint              _textureB;
    GLsizei             _texWidth;
    GLsizei             _texHeight;
    uint32_t            _seed;
    NSSize              _movieSize;
    
    PCOpenGLDiffPixelBuffer * bufferA;
    PCOpenGLDiffPixelBuffer * bufferB;
}

- (void)setMovieSize:(NSSize)size;

@property (nonatomic, retain, readwrite) PCOpenGLDiffPixelBuffer * bufferA;
@property (nonatomic, retain, readwrite) PCOpenGLDiffPixelBuffer * bufferB;

@end
