//
//  PCVideoControllerContainer.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 8/11/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCVideoController.h"
#import "PCVideoDragView.h"

@interface PCVideoControllerContainer : NSView <PCVideoControllerDelegate>{
    PCVideoController * videoController;
    PCVideoDragView * mainView;
}

+ (PCVideoControllerContainer*)containerWithHostingView:(NSView*)nView;

- (PCVideoController*)videoController;
- (void)resizeWithSize:(NSSize)nSize;

@property (nonatomic, retain, readwrite) PCVideoController * videoController;
@property (nonatomic, retain, readwrite) PCVideoDragView * mainView;

@end
