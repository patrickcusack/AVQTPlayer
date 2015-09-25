//
//  PCVideoControllerViewController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 8/11/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCVideoController.h"
#import "PCVideoDragView.h"

@interface PCVideoControllerViewController : NSViewController <PCVideoControllerDelegate>{
    PCVideoController * videoController;
}

- (PCVideoController*)videoController;
- (void)disengageControllers;

- (void)addToWindow:(NSWindow*)window;
- (void)addToView:(NSView*)view;
- (void)removeFromWindow:(NSWindow*)window;

- (void)resizeWithSize:(NSSize)nSize;

@property (nonatomic, retain, readwrite) PCVideoController * videoController;
@property (assign) IBOutlet PCVideoDragView *mainView;

@end
