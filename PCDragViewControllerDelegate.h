//
//  PCDragViewControllerDelegate.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/20/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PCDragViewControllerDelegate <NSObject>
@optional
- (void)handleDragURL:(NSURL*)dragURL;
- (BOOL)canViewGoToFrame;
- (void)dragViewWantsToGoToFrame:(NSNumber*)frame;
- (void)dragViewWantsToGoToPercentage:(float)percentage;
- (CALayer*)controllerVideoLayer;
@end
