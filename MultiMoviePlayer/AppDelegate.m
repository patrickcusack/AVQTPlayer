//
//  AppDelegate.m
//  MultiMoviePlayer
//
//  Created by Patrick Cusack on 5/12/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "AppDelegate.h"
#import "PCKeyController.h"
#import "PCTransportHolderViewController.h"
#import "PCVideoDragView.h"
#import "PCMovieControllerProxy.h"

@interface AppDelegate ()

@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSView *mainView;
@property (assign) IBOutlet NSView *controllerView;

@property (assign) IBOutlet NSView *mainViewB;
@property (assign) IBOutlet NSView *controllerViewB;

@end

@implementation AppDelegate
@synthesize videoController;
@synthesize videoControllerB;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self buildControllerA];
    [self buildControllerB];
    
}

- (void)buildControllerA{
    
    [self setVideoController:[PCVideoController videoController]];
    [[self videoController] setContainerView:[self mainView]];
    [[self videoController] setDelegate:self];
    
    [(PCVideoDragView*)[self mainView] setController:[self videoController]];
    
    PCTransportHolderViewController * viewController = [[PCTransportHolderViewController alloc] init];
    CGFloat width = [[self controllerView] frame].size.width;
    CGFloat controllerHeight = [[viewController view] frame].size.height;
    
    [[viewController view] setFrameSize:NSMakeSize(width, controllerHeight)];
    [[viewController view] setWantsLayer:YES];
    [[viewController view] setAutoresizingMask:(NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable)];
    [viewController setTransportDelegate:(id <PCTransportDelegateProcotol>)[self videoController]];
    [viewController setEnabled:NO];
    [[self controllerView] addSubview:[viewController view]];
    
//    PCKeyController * kController = [[PCKeyController alloc] init];
//    [kController setDelegate:(id <PCKeyControllerDelegate>)[viewController keyControllerView]];
//    [[self window] setNextResponder:kController];
    
    [[self videoController] setIdentifier:@"A"];
    [viewController setIdentifier:@"A"];
    
}

- (void)buildControllerB{
    
    [self setVideoControllerB:[PCVideoController videoController]];
    [[self videoControllerB] setContainerView:[self mainViewB]];
    [[self videoControllerB] setDelegate:self];
    
    [(PCVideoDragView*)[self mainViewB] setController:[self videoControllerB]];
    
    PCTransportHolderViewController * viewController = [[PCTransportHolderViewController alloc] init];
    CGFloat width = [[self controllerViewB] frame].size.width;
    CGFloat controllerHeight = [[viewController view] frame].size.height;
    
    [[viewController view] setFrameSize:NSMakeSize(width, controllerHeight)];
    [[viewController view] setWantsLayer:YES];
    [[viewController view] setAutoresizingMask:(NSViewMinXMargin|NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable)];
    [viewController setTransportDelegate:(id <PCTransportDelegateProcotol>)[self videoControllerB]];
    [viewController setEnabled:NO];
    [[self controllerViewB] addSubview:[viewController view]];
    
//    PCKeyController * kController = [[PCKeyController alloc] init];
//    [kController setDelegate:(id <PCKeyControllerDelegate>)[viewController keyControllerView]];
//    [[self window] setNextResponder:kController];
    
    
    [[self videoControllerB] setIdentifier:@"B"];
    [viewController setIdentifier:@"B"];
}

- (void)applicationWillTerminate:(NSNotification *)notification{

}

- (BOOL)shouldLoadURL:(NSURL*)fileURL{
    return YES;
}

- (void)audioProxyFileWasCreated:(NSString*)proxyAVFilePath{
    NSLog(@"%@", proxyAVFilePath);
}

- (IBAction)showLayer:(id)sender {
    
    
}

@end
