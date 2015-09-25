//
//  PCVideoControllerViewController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 8/11/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCVideoControllerViewController.h"
#import "PCTransportHolderViewController.h"
#import "PCKeyController.h"

@interface PCVideoControllerViewController (){
    PCKeyController * keyController;
    NSView * controllerView;
}

@property (nonatomic, retain, readwrite) PCKeyController * keyController;
@property (nonatomic, assign, readwrite) NSView * controllerView;

@end

@implementation PCVideoControllerViewController
@synthesize videoController;
@synthesize keyController;
@synthesize controllerView;

- (NSString*)nibName{
    return @"PCVideoControllerViewController";
}

- (void)disengageControllers{
    [self setVideoController:nil];
}

- (void)dealloc{
    [self setKeyController:nil];
    [self setVideoController:nil];
    [self setControllerView:nil];
    [super dealloc];
}

+(NSString *)generateUUID{
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uString = (NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [uString autorelease];
}

- (void)awakeFromNib{

    NSString * identifier = [PCVideoControllerViewController generateUUID];

    [self setVideoController:[PCVideoController videoControllerQuicktimeDefered]];
    [[self videoController] setContainerView:[self mainView]];
    [[self videoController] setDelegate:self];

    [(PCVideoDragView*)[self mainView] setController:[self videoController]];

    PCTransportHolderViewController * viewController = [[PCTransportHolderViewController alloc] init];
    CGFloat width = [[self view] frame].size.width;
    CGFloat controllerHeight = [[viewController view] frame].size.height;
    [[viewController view] setFrameSize:NSMakeSize(width, controllerHeight)];
    [[viewController view] setWantsLayer:YES];
    [[viewController view] setAutoresizingMask:(NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable)];
    [viewController setTransportDelegate:(id <PCTransportDelegateProcotol>)[self videoController]];
    [viewController setEnabled:NO];
    [[self view] addSubview:[viewController view]];
    [self setControllerView:[viewController view]];

    [viewController setIdentifier:identifier];
    [[self videoController] setIdentifier:identifier];

    PCKeyController * kController = [[PCKeyController alloc] init];
    [kController setDelegate:(id <PCKeyControllerDelegate>)[viewController keyControllerView]];
    [self setKeyController:kController];
    
}

- (void)addToWindow:(NSWindow*)window{
    [self addToView:[window contentView]];
}

- (void)removeFromWindow:(NSWindow*)window{
    [[self view] removeFromSuperview];
    [window setNextResponder:nil];
}

- (void)addToView:(NSView*)nView{
    [nView addSubview:[self view]];
    [[nView window] setNextResponder:[self keyController]];
}

- (void)removeFromView:(NSView*)nView{
    [[self view] removeFromSuperview];
    [[nView window] setNextResponder:nil];
}

- (void)resizeWithSize:(NSSize)nSize{
    NSRect bounds = NSMakeRect(0, 0, nSize.width, nSize.height);
    CGFloat offset = 40;
    [[self view] setFrame:NSMakeRect(0, 0, nSize.width, nSize.height)];
    [[self mainView] setFrameOrigin:NSMakePoint(0, offset)];
    [[self mainView] setFrameSize:NSMakeSize(bounds.size.width, bounds.size.height - offset)];
    [[self controllerView] setFrameOrigin:NSMakePoint(0, 0)];
}

@end
