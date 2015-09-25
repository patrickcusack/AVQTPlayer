//
//  PCMovieBasePlayer.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/1/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Quartz/Quartz.h>
#import <CoreMedia/CoreMedia.h>

typedef void (^PCMovieReadyToPlayBlock)(BOOL ready);

NSString * NSStringFromCMTime(CMTime time);

@interface PCMoviePlayer : NSObject{
    AVPlayer * player;
    
    CMTimeScale videoAssetTimeScale;
    CMTimeScale assetTimeScale;
    float nominalFrameRate;
    CMTimeScale naturalTimeScale;
    CMTime duration;
    
    BOOL isPlaying;
    BOOL readyToPlay;
    PCMovieReadyToPlayBlock readyBlock;
    
    BOOL shouldResizeWindowToMatch;
    
    AVPlayerItem * playerItem;
    AVAsset * currentAsset;
    NSURL * currentURL;
}

- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCMovieReadyToPlayBlock)block;
- (void)addAudioURLToCurrentVideoAsset:(NSURL *)audioURL withReadyBlock:(PCMovieReadyToPlayBlock)block;
- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL error:(NSError**)err;

- (void)addPlayerItemToPlayer:(AVPlayerItem*)playerItem;
- (void)addPlayerItemToPlayer:(AVPlayerItem*)playerItem withCallBack:(PCMovieReadyToPlayBlock)block;

- (void)togglePlay;
- (void)play;
- (void)pause;
- (void)stepBackward;
- (void)stepForward;
- (void)setRate:(float)nRate;
- (void)goToFrame:(NSNumber*)frameNumber;
- (void)goToPercentage:(float)percentage;
- (void)goToTime:(CMTime)nTime;
- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart;
- (NSUInteger)getTime;

- (AVPlayerItem*)playerItem;
- (CGSize)sizeOfVideoTrack;

- (CMTimeValue)frameSize;

- (CMTime)currentPlayerTime;
- (NSString*)currentPlayerTimeString;
- (NSUInteger)currentFrame;

@property (nonatomic, retain, readwrite) AVPlayer * player;
@property (nonatomic, assign, readwrite) BOOL isPlaying;
@property (nonatomic, assign, readwrite) BOOL readyToPlay;

@property (nonatomic, assign, readwrite) CMTimeScale videoAssetTimeScale;
@property (nonatomic, assign, readwrite) CMTimeScale assetTimeScale;
@property (nonatomic, assign, readwrite) float nominalFrameRate;
@property (nonatomic, assign, readwrite) CMTimeScale naturalTimeScale;
@property (nonatomic, assign, readwrite) CMTime duration;

@property (nonatomic, copy, readwrite) PCMovieReadyToPlayBlock readyBlock;

@property (nonatomic, assign, readwrite) BOOL shouldResizeWindowToMatch;
@property (nonatomic, retain, readwrite) AVPlayerItem * playerItem;
@property (nonatomic, retain, readwrite) AVAsset * currentAsset;
@property (nonatomic, retain, readwrite) NSURL * currentURL;

@end
