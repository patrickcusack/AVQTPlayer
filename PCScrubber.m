    //
//  PCScrubber.m
//  IOSurfaceTest
//
//  Created by Patrick Cusack on 4/29/15.
//  Copyright (c) 2015 Paolo Manna. All rights reserved.
//

#import "PCScrubber.h"

@implementation PCScrubberCell
@synthesize parent;


- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView{
    [[self parent] markCurrentRate:[self doubleValue]];
    return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag{
    if (flag == YES) {
        [[self parent] mouseWasUnclicked];
    }
}

@end

@implementation PCScrubber
@synthesize delegate;

- (void)awakeFromNib{
    PCScrubberCell * cell = [[[PCScrubberCell alloc] init] autorelease];
    [cell setParent:self];
    [self setCell:cell];
    [self setMinValue:-5.];
    [self setDoubleValue:0.0];
    [self setMaxValue:5.];
    [self setContinuous:YES];
}

- (void)mouseDown:(NSEvent *)theEvent  {
    if ([delegate respondsToSelector: @selector(setRate:)]){
        [delegate setRate:self];
    }
    
    [super mouseDown:theEvent];
}

- (void)markCurrentRate:(float)nValue{
    if ([delegate respondsToSelector: @selector(setRate:)]){
        [delegate setRate:self];
    }
}


- (void)mouseWasUnclicked{
    [self setDoubleValue:1.0];
    if ([delegate respondsToSelector: @selector(setRate:)]){
        [delegate setRate:self];
    }
    [self setDoubleValue:0.0];
}

@end