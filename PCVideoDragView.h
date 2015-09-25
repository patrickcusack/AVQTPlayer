//
//  PCVideoDragView.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/20/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCDragViewControllerDelegate.h"

@interface PCVideoDragView : NSView{
    id <PCDragViewControllerDelegate> controller;
}

@property (nonatomic, assign, readwrite) id <PCDragViewControllerDelegate> controller;

@end
