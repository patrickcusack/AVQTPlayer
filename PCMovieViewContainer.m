//
//  PCMovieViewContainer.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/10/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import "PCMovieViewContainer.h"
#import "PCMovieViewPlayer.h"

@implementation PCMovieViewContainer
@synthesize currentPlayer;
@synthesize spinnerIndicator;

+ (instancetype)containerForView:(NSView*)parentView{
    PCMovieViewContainer * view = [[PCMovieViewContainer alloc] initWithFrame:[parentView bounds]];
    [parentView addSubview:view];
    return [view autorelease];
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setWantsLayer:YES];
        
        NSProgressIndicator * spinner = [[NSProgressIndicator alloc] initWithFrame:[self frame]];
        [spinner setStyle:NSProgressIndicatorSpinningStyle];
        [spinner setHidden:YES];
        [spinner setAutoresizingMask:(NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)];
        [self setSpinnerIndicator:spinner];
        [self addSubview:spinner];
        [spinner release];
        
        [self setPostsBoundsChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(frameChanged:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self spinnerIndicator] removeFromSuperview];
    if ([self currentPlayer]) {[self removeCurrentPlayer:[self currentPlayer]];}
    [self setCurrentPlayer:nil];
    
    [super dealloc];
}

- (void)frameChanged:(NSNotification*)aNotif{
    if ([self currentPlayer]) {
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
        [[self currentPlayer] positionInFrame:[self bounds]];
        [CATransaction commit];
    }
}

- (void)addPlayer:(PCMovieViewPlayer*)nPLayer{
    [self removeCurrentPlayer:[self currentPlayer]];
    [nPLayer addToContainer:self];
    [self setCurrentPlayer:nPLayer];
}

- (void)removeCurrentPlayer:(PCMovieViewPlayer*)nPLayer{
    [[self currentPlayer] removeFromContainer];
    [self setCurrentPlayer:nil];
}

- (void)showSpinner{
    [[self spinnerIndicator] startAnimation:self];
    [[self spinnerIndicator] setHidden:NO];
}

- (void)hideSpinner{
    [[self spinnerIndicator] setHidden:YES];
    [[self spinnerIndicator] stopAnimation:self];
}

- (void)resizeWindowWithContentSize:(NSSize)contentSize animated:(BOOL)animated{
    CGFloat titleBarHeight = [[self window] frame].size.height - [[[self window] contentView] frame].size.height;
    CGSize windowSize = CGSizeMake(contentSize.width, contentSize.height + titleBarHeight);
    
    // Optional: keep it centered
    float originX = self.window.frame.origin.x + (self.window.frame.size.width - windowSize.width) / 2;
    float originY = self.window.frame.origin.y + (self.window.frame.size.height - windowSize.height) / 2;
    NSRect windowFrame = CGRectMake(originX, originY, windowSize.width, windowSize.height);
    
    [[self window] setFrame:windowFrame display:YES animate:animated];
}


@end
