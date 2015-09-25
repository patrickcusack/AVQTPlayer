//
//  PCVideoDragView.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/20/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCVideoDragView.h"
#import <QuartzCore/QuartzCore.h>
#import "PCTCformatter.h"

@interface PCVideoDragView (){
    NSMutableArray * localLayers;
    NSTextField * frameField;
    PCTCformatter * timeFormatter;
    NSNumber *selectedFrame;
}

@property (nonatomic, retain, readwrite) NSMutableArray * localLayers;
@property (nonatomic, retain, readwrite) NSTextField * frameField;
@property (nonatomic, retain, readwrite) PCTCformatter * timeFormatter;
@property (nonatomic, retain, readwrite) NSNumber *selectedFrame;

@end

@implementation PCVideoDragView
@synthesize controller;
@synthesize localLayers;
@synthesize frameField;
@synthesize timeFormatter;
@synthesize selectedFrame;

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (void)awakeFromNib{
    [self setLocalLayers:[NSMutableArray array]];
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    
    [self setWantsLayer:YES];
    [[self layer] setContentsScale:2.0];
    
    CGColorRef color = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0);
    [[self layer] setBackgroundColor:color];
    CGColorRelease(color);
    
    CALayer * imageLayer = [CALayer layer];
    [imageLayer setPosition:CGPointMake(CGRectGetMidX([[self layer] bounds]), CGRectGetMidY([[self layer] bounds]))];
    [imageLayer setBounds:[[self layer] bounds]];
    [imageLayer setContentsGravity:kCAGravityResizeAspect];
    [imageLayer setCornerRadius:5.0];
    [imageLayer setMasksToBounds:YES];
    [imageLayer setBorderColor:CGColorGetConstantColor(kCGColorBlack)];
    [imageLayer setBorderWidth:4.0];
    [imageLayer setContentsScale:2.0];
    [imageLayer setAutoresizingMask: kCALayerWidthSizable];
    [imageLayer setContents:[NSImage imageNamed:@"2pop"]];
    [imageLayer setOpacity:1.0];
    [[self layer] addSublayer:imageLayer];
    [[self localLayers] addObject:imageLayer];
    
    [self setPostsFrameChangedNotifications:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundsDidChangeNotification:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    
    CATextLayer * nTextLayer = [self textLayer];
    [[self localLayers] addObject:nTextLayer];
    [[self layer] addSublayer:nTextLayer];
    
    [[self layer] setBorderWidth:4.0];
    [[self layer] setBorderColor:CGColorGetConstantColor(kCGColorBlack)];
    
    [self buildFrameEntryView];
    
    [self boundsDidChangeNotification:nil];

}

- (void)dealloc{
    [self tearDownFrameEntryView];
    [self setFrameField:nil];
    [self setTimeFormatter:nil];
    [self setLocalLayers:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)buildFrameEntryView{
    [self setTimeFormatter:[PCTCformatter genericPCTCformatter]];
    [[self timeFormatter] setFrameRate:23.98];
    [[self timeFormatter] setDisplayType:PCTCformatFrames];
    
    [self setFrameField:[[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 22)] autorelease]];
    [[self frameField] setAlignment:NSCenterTextAlignment];
    NSRect nFrame = [self bounds];
    NSPoint nPoint = NSMakePoint(NSMidX(nFrame) - [[self frameField] frame].size.width/2, NSMidY(nFrame) - [[self frameField] frame].size.height/2);
    [[self frameField] setFrameOrigin:nPoint];
    [[self frameField] setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin|NSViewMaxYMargin|NSViewMinYMargin];
    [[self frameField] setHidden:YES];
    [[self frameField] setEnabled:NO];
    [self addSubview:[self frameField]];
    
    [[self frameField] setFormatter:[self timeFormatter]];
    
    [[self frameField] bind:@"value" toObject:self withKeyPath:@"selectedFrame" options:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification object:nil];
    
    [self setSelectedFrame:[NSNumber numberWithUnsignedLongLong:0]];
}

- (void)tearDownFrameEntryView{
    [[self frameField] unbind:@"value"];
    [[self frameField] removeFromSuperview];
}

- (void)mouseDragged:(NSEvent *)theEvent{
    
    if ([self controller] && [[self controller] respondsToSelector:@selector(dragViewWantsToGoToPercentage:)]) {
        CGFloat x = [self convertPoint:[theEvent locationInWindow] fromView:nil].x;
        [[self controller] dragViewWantsToGoToPercentage:(float)x/[self bounds].size.width];
    }
    
}

- (void)mouseUp:(NSEvent *)event{
    NSInteger clickCount = [event clickCount];
    
    if (2 == clickCount){
        if ([self controller] && [[self controller] respondsToSelector:@selector(canViewGoToFrame)]) {
            
            if ([[self controller] canViewGoToFrame] == NO) {
                return;
            }
            
            CALayer * frameLayer  = [[self frameField] layer];
            [[self layer] insertSublayer:frameLayer above:[[self controller] controllerVideoLayer]];

            [[self frameField] setHidden:NO];
            [[self frameField] setEnabled:YES];
            [[self window] makeFirstResponder:[self frameField]];
        }
        return;
    }
    
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent{
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    
    NSMenuItem *menuItem =  [[[NSMenuItem alloc] initWithTitle:@"Frames"
                                                       action:@selector(setDisplayType:)
                                                keyEquivalent:@""] autorelease];
    [menuItem setTag:PCTCformatFrames];
    [menu addItem:menuItem];
    [menuItem setState:([menuItem tag] == [[self timeFormatter] displayType] ? NSOnState : NSOffState)];
    
    menuItem =  [[[NSMenuItem alloc] initWithTitle:@"TimeCode"
                                            action:@selector(setDisplayType:)
                                     keyEquivalent:@""] autorelease];
    [menuItem setTag:PCTCformatTimeCode];
    [menu addItem:menuItem];
    [menuItem setState:([menuItem tag] == [[self timeFormatter] displayType] ? NSOnState : NSOffState)];
    
    menuItem =  [[[NSMenuItem alloc] initWithTitle:@"Feet and Frames"
                                            action:@selector(setDisplayType:)
                                     keyEquivalent:@""] autorelease];
    [menuItem setTag:PCTCformatFeetAndFrames];
    [menu addItem:menuItem];
    [menuItem setState:([menuItem tag] == [[self timeFormatter] displayType] ? NSOnState : NSOffState)];
    
    
    return menu;
}

- (IBAction)setDisplayType:(id)sender{
    [[self timeFormatter] setDisplayType:(int)[sender tag]];
    [sender setState:NSOnState];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    
    if ([self controller] && [[self controller] respondsToSelector:@selector(canViewGoToFrame)]) {
        if ([[self controller] canViewGoToFrame] == NO) {
            return NO;
        }
    }
    
    if ([menuItem action] == @selector(setDisplayType:)){
        if ([menuItem tag] == [[self timeFormatter] displayType]) {
            [menuItem setState:NSOnState];
        } else {
            [menuItem setState:NSOffState];
        }
    }
    return YES;
}

- (void)editingDidEnd:(NSNotification*)aNotif{
    if ([self controller] && [aNotif object] == [self frameField] ) {
        
        NSString * frameFieldValue = [[self frameField] stringValue];
        
        if (![frameFieldValue isEqualToString:@""]) {
            
            NSUInteger frames = [frameField intValue];
            
            if ([[self timeFormatter] displayType] == PCTCformatTimeCode) {
                frames = [[self timeFormatter] convertTimeCodeNSUIntegerFrames:frameFieldValue];
            } else if ([[self timeFormatter] displayType] == PCTCformatFeetAndFrames){
                frames = [[self timeFormatter] convertFeetAndFramesToNSUIntegerFrames:frameFieldValue];
            }
            
            [[self controller] dragViewWantsToGoToFrame:[NSNumber numberWithInteger:frames]];
            
        }

        [[self frameField] setHidden:YES];
        [[self frameField] setEnabled:NO];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            if ([files count] == 1) {
                
                for (NSString * extension in @[@"mov", @"wav", @"aiff", @"aif", @"mp3"]) {
                    if ([[files objectAtIndex:0] rangeOfString:extension].location != NSNotFound) {
                        return NSDragOperationLink;
                    }
                }
            }
        }
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        if (sourceDragMask & NSDragOperationLink) {
            if ([self controller] && [[self controller] respondsToSelector:@selector(handleDragURL:)]) {
                [[self controller] handleDragURL:[NSURL fileURLWithPath:[files objectAtIndex:0]]];
            }
        }
    }
    return YES;
}

- (void)boundsDidChangeNotification:(NSNotification*)aNotif{
    
    for (CALayer* layer in [self localLayers]) {
        if ([layer class] == [CATextLayer class]) {
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            
            if ([self bounds].size.width < 480){
                [(CATextLayer*)layer setFontSize:48.0 * ([self bounds].size.width/480)];
                [(CATextLayer*)layer setBounds:CGRectMake(0, 0, [[self layer] bounds].size.width, 52 * ([self bounds].size.width/480.0))];
            } else {
                [(CATextLayer*)layer setFontSize:48.0];
                [(CATextLayer*)layer setBounds:CGRectMake(0, 0, [[self layer] bounds].size.width, 52)];
            }
            
            [layer setPosition:CGPointMake(CGRectGetMidX([self bounds]), CGRectGetMidY([self bounds]))];
            [CATransaction commit];
            
            
        } else {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            [layer setPosition:CGPointMake(CGRectGetMidX([self bounds]), CGRectGetMidY([self bounds]))];
            [layer setBounds:[[self layer] bounds]];
            [CATransaction commit];
        }
    }
}

- (CATextLayer*)textLayer{
    
    CGColorRef clearColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0,1.0);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    
    CATextLayer * nTextLayer = [CATextLayer layer];
    [nTextLayer setBackgroundColor:clearColor];
    [nTextLayer setForegroundColor:whiteColor];
    [nTextLayer setShadowColor:shadowColor];
    
    [nTextLayer setShadowOffset:CGSizeMake(0, -2)];
    [nTextLayer setShadowOpacity:1.0];
    [nTextLayer setPosition:CGPointMake(CGRectGetMidX([[self layer] bounds]), CGRectGetMidY([[self layer] bounds]))];
    [nTextLayer setBounds:CGRectMake(0, 0, [[self layer] bounds].size.width, 52)];
    [nTextLayer setContentsGravity:kCAGravityResize];
    [nTextLayer setAutoresizingMask: kCALayerWidthSizable];
    [nTextLayer setAlignmentMode:kCAAlignmentCenter];
    [nTextLayer setContentsScale:2.0];
    [nTextLayer setFontSize:48.0];
    
    [nTextLayer setString:@"DROP MOVIE"];
    NSFont * font = [NSFont fontWithName:@"Futura" size:48.0];
    CFStringRef postScriptName = CTFontCopyPostScriptName((CTFontRef)font);
    [nTextLayer setFont:postScriptName];
    CFRelease(postScriptName);
    
    CFRelease(clearColor);
    CFRelease(whiteColor);
    CFRelease(shadowColor);
    CFRelease(redColor);
    CFRelease(blueColor);
    
    return nTextLayer;
}

@end
