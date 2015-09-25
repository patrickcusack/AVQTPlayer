//
//  PCKeyController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/19/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PCKeyControllerDelegate.h"

@interface PCKeyController : NSResponder {
    id <PCKeyControllerDelegate> delegate;
}

@property (nonatomic, assign, readwrite) id <PCKeyControllerDelegate> delegate;

@end
