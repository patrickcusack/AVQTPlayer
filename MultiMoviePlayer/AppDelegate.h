//
//  AppDelegate.h
//  MultiMoviePlayer
//
//  Created by Patrick Cusack on 5/12/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCVideoController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, PCVideoControllerDelegate, NSWindowDelegate>{
    PCVideoController * videoController;
    PCVideoController * videoControllerB;
}

- (IBAction)showLayer:(id)sender;

@property (nonatomic, retain, readwrite) PCVideoController * videoController;
@property (nonatomic, retain, readwrite) PCVideoController * videoControllerB;

@end

