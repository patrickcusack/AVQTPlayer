//
//  PCMovieViewContainer.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/10/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@class PCMovieViewPlayer;

@interface PCMovieViewContainer : NSView{
    PCMovieViewPlayer * currentPlayer;
    NSProgressIndicator * spinnerIndicator;
}

+ (instancetype)containerForView:(NSView*)parentView;

- (void)addPlayer:(PCMovieViewPlayer*)nPLayer;
- (void)removeCurrentPlayer:(PCMovieViewPlayer*)nPLayer;

- (void)showSpinner;
- (void)hideSpinner;
- (void)resizeWindowWithContentSize:(NSSize)contentSize animated:(BOOL)animated;

@property (nonatomic, retain, readwrite) PCMovieViewPlayer * currentPlayer;
@property (nonatomic, assign, readwrite) NSProgressIndicator * spinnerIndicator;

@end
