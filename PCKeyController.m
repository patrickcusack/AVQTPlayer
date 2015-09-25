//
//  PCKeyController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/19/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCKeyController.h"

@implementation PCKeyController
@synthesize delegate;

- (BOOL)acceptsFirstResponder{
    return YES;
}

- (BOOL)becomeFirstResponder{
    return YES;
}

- (BOOL)resignFirstResponder{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent{
    
    if ([[self delegate] willHandleKeyPress:theEvent]) {
        [delegate keyWasPressed:theEvent];
        return;
    }
    
    [super keyDown:theEvent];
}

@end
