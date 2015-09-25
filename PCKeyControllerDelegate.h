//
//  PCKeyControllerDelegate.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/19/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PCKeyControllerDelegate <NSObject>
- (BOOL)willHandleKeyPress:(NSEvent*)theEvent;
- (void)keyWasPressed:(NSEvent*)theEvent;
@end
