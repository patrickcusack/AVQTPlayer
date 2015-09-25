//
//  PCOpenGLDiffController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 7/1/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCVideoTapDelegateProtocol.h"
#import "PCOpenGLScreenInfoProtocol.h"
#import "VideoOutputLayer.h"
#import "PCOpenGLDiffLayer.h"
#import "PCOpenGLLayer.h"

@interface PCOpenGLDiffController : NSObject <PCVideoTapDelegateProtocol, PCOpenGLLayerContextProtocol, PCOpenGLScreenInfoProtocol>{
    VideoOutputLayer * layerA;
    VideoOutputLayer * layerB;
    PCOpenGLLayer * diffLayer;
    BOOL useOpenCV;
    BOOL shouldSynchronize;
}

- (void)setMovieSize:(NSSize)mSize;
- (void)addDifferenceScaleSlider:(id)aSlider;
- (void)addDifferenceTextField:(id)nTexfield;


@property (nonatomic, assign, readwrite) VideoOutputLayer * layerA;
@property (nonatomic, assign, readwrite) VideoOutputLayer * layerB;
@property (nonatomic, retain, readwrite) PCOpenGLLayer * diffLayer;
@property (nonatomic, assign, readwrite) BOOL useOpenCV;
@property (nonatomic, assign, readwrite) BOOL shouldSynchronize;

@end
