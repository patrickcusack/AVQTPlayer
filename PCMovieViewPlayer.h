//
//  PCMovieViewPlayer.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/10/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <CoreMedia/CoreMedia.h>
#import "PCMovieViewContainer.h"

typedef void (^PCMovieReadyToPlayBlock)(id player, BOOL ready);

@interface PCMovieViewPlayer : NSObject{
    AVPlayer * player;
    
    CMTimeScale videoAssetTimeScale;
    CMTimeScale assetTimeScale;
    float nominalFrameRate;
    float naturalTimeScale;
    
    id timeObserver;
    dispatch_queue_t observerQueue;
    
    BOOL isPlaying;
    BOOL readyToPlay;
    PCMovieReadyToPlayBlock readyBlock;
    
    AVPlayerLayer * playerLayer;
    CATextLayer * textLayer;
    
    PCMovieViewContainer * container;
    BOOL shouldResizeWindowToMatch;
}

+ (PCMovieViewPlayer*)player;
+ (PCMovieViewPlayer*)playerWithContainer:(PCMovieViewContainer*)nContainer;

- (void)addPlayerItemToPlayer:(AVPlayerItem*)playerItem;
- (void)addObserver;

- (void)addToContainer:(PCMovieViewContainer*)nContainer;
- (void)removeFromContainer;

- (void)positionInFrame:(NSRect)frame;

- (void)play;
- (void)pause;
- (void)stepBackwards;
- (void)stepFoward;
- (void)goToFrame:(NSNumber*)frameNumber;


@property (nonatomic, retain, readwrite) AVPlayer * player;
@property (nonatomic, retain, readwrite) id timeObserver;
@property (nonatomic, assign, readwrite) BOOL isPlaying;
@property (nonatomic, assign, readwrite) BOOL readyToPlay;

@property (nonatomic, assign, readwrite) CMTimeScale videoAssetTimeScale;
@property (nonatomic, assign, readwrite) CMTimeScale assetTimeScale;
@property (nonatomic, assign, readwrite) float nominalFrameRate;
@property (nonatomic, assign, readwrite) float naturalTimeScale;

@property (nonatomic, retain, readwrite) AVPlayerLayer * playerLayer;
@property (nonatomic, retain, readwrite) CATextLayer * textLayer;
@property (nonatomic, assign, readwrite) PCMovieViewContainer * container;
@property (nonatomic, assign, readwrite) BOOL shouldResizeWindowToMatch;

@property (nonatomic, copy, readwrite) PCMovieReadyToPlayBlock readyBlock;

@end
