//
//  PCOpenGLDiffPixelBuffer.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 6/29/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <CoreVideo/CoreVideo.h>
#import "PCVideoTapDelegateProtocol.h"

@interface PCOpenGLDiffPixelBuffer : NSObject{
    size_t width;
    size_t height;
    GLint internalformat;
    GLenum format;
    GLenum type;
    GLubyte * data;
    NSUInteger numberOfBytes;
    NSUInteger currentFrame;
    BOOL hasBeenRead;
}

+ (PCOpenGLDiffPixelBuffer*)bufferWithBufferStruct:(PCVideoTapStruct)nStruct;
- (instancetype)initWithPixelBufferStruct:(PCVideoTapStruct)nStruct;

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)bufferRef
                     internalFormat:(GLint)iFormat
                          andFormat:(GLenum)nFormat
                            andType:(GLenum)nType;

- (void)setDataOnTexture:(GLuint)texture;

- (NSUInteger)pixelBufferSize;
- (GLubyte *)data;


@property (nonatomic, assign, readwrite) size_t width;
@property (nonatomic, assign, readwrite) size_t height;
@property (nonatomic, assign, readwrite) NSUInteger numberOfBytes;
@property (nonatomic, assign, readwrite) NSUInteger currentFrame;
@property (nonatomic, assign, readwrite) BOOL hasBeenRead;

@end
