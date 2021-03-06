//
//  PCOpenGLScreen.h
//  CAOpenGLLayerTest
//
//  Created by Patrick Cusack on 7/3/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCPixelBufferConsumerProtocol.h"
#import "PCOpenGLScreenProviderProtocol.h"
#import "PCOpenGLScreenInfoProtocol.h"

@class PCOpenGLDiffPixelBuffer;

@interface PCOpenGLOpenCVScreen : NSObject <PCPixelBufferConsumerProtocol, PCOpenGLScreenProviderProtocol>{
    PCOpenGLDiffPixelBuffer * bufferA;
    PCOpenGLDiffPixelBuffer * bufferB;
    NSMutableArray * buffersA;
    NSMutableArray * buffersB;
    id <PCOpenGLScreenInfoProtocol> delegate;
    BOOL shouldSynchronize;
}

- (void)draw;

@property (nonatomic, retain, readwrite) PCOpenGLDiffPixelBuffer * bufferA;
@property (nonatomic, retain, readwrite) PCOpenGLDiffPixelBuffer * bufferB;
@property (nonatomic, retain, readwrite) NSMutableArray * buffersA;
@property (nonatomic, retain, readwrite) NSMutableArray * buffersB;
@property (nonatomic, assign, readwrite) id <PCOpenGLScreenInfoProtocol> delegate;
@property (nonatomic, assign, readwrite) BOOL shouldSynchronize;

@end
