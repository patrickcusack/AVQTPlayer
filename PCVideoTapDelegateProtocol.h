//
//  PCSiphonDelegateProtocol.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 6/30/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <OpenGl/gl.h>

typedef struct {
    CVPixelBufferRef buffer;
    GLint internalFormat;
    GLenum format;
    GLenum type;
    NSUInteger numberOfBytes;
    NSUInteger currentFrame;
} PCVideoTapStruct;

@protocol PCVideoTapDelegateProtocol <NSObject>
- (void)addPixelBuffer:(PCVideoTapStruct)bufferStruct fromObject:(id)nDelegate;
- (void)setMovieSize:(NSSize)mSize;
@end
