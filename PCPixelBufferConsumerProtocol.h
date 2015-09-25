//
//  PCPixelBufferConsumerProtocol.h
//  ImageComparisonTest
//
//  Created by Patrick Cusack on 7/4/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PCOpenGLDiffPixelBuffer;

@protocol PCPixelBufferConsumerProtocol <NSObject>
- (void)setBufferA:(PCOpenGLDiffPixelBuffer*)buffer;
- (void)setBufferB:(PCOpenGLDiffPixelBuffer*)buffer;
- (void)addBufferToBuffersA:(PCOpenGLDiffPixelBuffer*)buffer;
- (void)addBufferToBuffersB:(PCOpenGLDiffPixelBuffer*)buffer;
@end
