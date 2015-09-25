//
//  NSObject+PCVideoControllerDisplay.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 7/5/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCVideoController+PCVideoControllerDisplay.h"
#import "PCAVMovieController.h"

@implementation PCVideoController (PCVideoControllerDisplay)

- (void)dim{
    [[[self containerView] layer] setOpacity:0.3];
    
    if ([self avMovieController]) {
//        return [(CALayer*)[[self avMovieController] videoOutputLayer] setOpacity:0.5];
    }
}

- (void)undim{
    [[[self containerView] layer] setOpacity:1.0];
    
    if ([self avMovieController]) {
//        return [(CALayer*)[[self avMovieController] videoOutputLayer] setOpacity:1.0];
    }
}

@end
