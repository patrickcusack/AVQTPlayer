//
//  PCVideoControllerContainer.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 8/11/15.
//  Copyright (c) 2015 Paolo Manna. All rights reserved.
//

#import "PCVideoControllerContainer.h"
#import "PCTransportHolderViewController.h"
#import "PCKeyController.h"

@implementation PCVideoControllerContainer
@synthesize videoController;
@synthesize mainView;

+ (PCVideoControllerContainer*)containerWithHostingView:(NSView*)nView{
    
    PCVideoControllerContainer * container = [[[PCVideoControllerContainer alloc] initWithFrame:[nView bounds]] autorelease];

    NSString * identifier = @"MyMovieWindowController";
    
    PCVideoController * videoController = [PCVideoController videoController];
    [videoController setContainerView:[container mainView]];
    [videoController setDelegate:container];
    [container setVideoController:videoController];
    
    [(PCVideoDragView*)[container mainView] setController:[container videoController]];

    PCTransportHolderViewController * viewController = [[PCTransportHolderViewController alloc] init];
    CGFloat width = [container frame].size.width;
    CGFloat controllerHeight = [[viewController view] frame].size.height;
    [[viewController view] setFrameSize:NSMakeSize(width, controllerHeight)];
    [[viewController view] setWantsLayer:YES];
    [[viewController view] setAutoresizingMask:(NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable)];
    [viewController setTransportDelegate:(id <PCTransportDelegateProcotol>)[container videoController]];
    [viewController setEnabled:NO];
    [container addSubview:[viewController view]];
    
    [viewController setIdentifier:identifier];
    [videoController setIdentifier:identifier];
    
    PCKeyController * kController = [[PCKeyController alloc] init];
    [kController setDelegate:(id <PCKeyControllerDelegate>)[viewController keyControllerView]];
    [[nView window] setNextResponder:kController];
    
    return container;
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setMainView:[[[PCVideoDragView alloc] initWithFrame:frame] autorelease]];
        [self addSubview:[self mainView]];
        [self resizeWithSize:frame.size];
    }
    return self;
}

- (void)dealloc{
    [self setVideoController:nil];
    [self setMainView:nil];
    [super dealloc];
}

- (BOOL)shouldLoadURL:(NSURL*)fileURL{
    return YES;
}

- (void)audioProxyFileWasCreated:(NSString*)proxyAVFilePath{
    
}

- (void)didLoadMovie:(PCVideoController*)vController{
    
}

- (void)resizeWithSize:(NSSize)nSize{
    NSRect bounds = NSMakeRect(0, 0, nSize.width, nSize.height);
    CGFloat offset = 40;
    [[self mainView] setFrameOrigin:NSMakePoint(0, offset)];
    [[self mainView] setFrameSize:NSMakeSize(bounds.size.width, bounds.size.height - offset)];
}

@end
