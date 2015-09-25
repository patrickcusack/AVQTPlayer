//
//  PCOpenGLDiffPixelBuffer.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 6/29/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCOpenGLDiffPixelBuffer.h"

@implementation PCOpenGLDiffPixelBuffer
@synthesize width;
@synthesize height;
@synthesize numberOfBytes;
@synthesize hasBeenRead;
@synthesize currentFrame;

+ (PCOpenGLDiffPixelBuffer*)bufferWithBufferStruct:(PCVideoTapStruct)nStruct{
    PCOpenGLDiffPixelBuffer * obj = [[PCOpenGLDiffPixelBuffer alloc] initWithPixelBufferStruct:nStruct];
    return [obj autorelease];
}

- (instancetype)initWithPixelBufferStruct:(PCVideoTapStruct)nStruct{
    self = [super init];
    if (self) {
        CVPixelBufferLockBaseAddress(nStruct.buffer, 0);
        width	= CVPixelBufferGetWidth(nStruct.buffer);
        height	= CVPixelBufferGetHeight(nStruct.buffer);
        internalformat = nStruct.internalFormat;
        format = nStruct.format;
        type = nStruct.type;
        numberOfBytes = nStruct.numberOfBytes;
        currentFrame = nStruct.currentFrame;
        size_t size = CVPixelBufferGetDataSize(nStruct.buffer);
        data = (GLubyte*)malloc(size);
        memcpy(data, (GLubyte *)CVPixelBufferGetBaseAddress(nStruct.buffer), size);

        bool writeToFile = false;
        if (writeToFile) {
            FILE * pFile = fopen("test", "wb");
            if (pFile) {
                fwrite(data, sizeof(uint8_t), width * height * numberOfBytes, pFile);
                fclose(pFile);
            }
        }
        
        CVPixelBufferUnlockBaseAddress(nStruct.buffer, 0);
    }
    return self;
}

- (void)dealloc{
    
    if (data) {
        free(data);
        data = nil;
    }
    
    [super dealloc];
}

- (void)setDataOnTexture:(GLuint)texture{
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, internalformat, (GLsizei)width, (GLsizei)height, 0, format, type, data);
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
    
}

- (NSUInteger)pixelBufferSize{
    return width * height * numberOfBytes;
}

- (GLubyte *)data{
    return data;
}


@end
