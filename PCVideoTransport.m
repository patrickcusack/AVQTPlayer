//
//  PCVideoTransport.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/13/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCVideoTransport.h"

@implementation PCVideoTransport

- (NSView*)transportView{
    [[self view] setWantsLayer:YES];
    [[[self view] layer] setOpaque:YES];
    return [self view];
}

@end
