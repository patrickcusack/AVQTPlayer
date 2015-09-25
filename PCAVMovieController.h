//
//  PCAVMovieController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/12/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCMovieControllerProxy.h"
#import "PCPlayerItem.h"
#import "PCMoviePlayer.h"
#import "VideoOutputLayer.h"
#import "PCMovieControllerProxy.h"
#import "PCVideoTapDelegateProtocol.h"
#import "PCTimeDisplayController.h"

//typedef void (^PCAVMovieReadyToPlay)(BOOL ready);

@interface PCAVMovieController : NSObject <PCMovieControllerProxy>{
    PCMoviePlayer * moviePlayer;
    VideoOutputLayer * videoOutputLayer;
    CATextLayer * timeDisplayLayer;
    
    BOOL showTime;
    BOOL displayVerboseTime;
    
    id timeObserver;
    dispatch_queue_t observerQueue;
    
    NSString * identifier;
    id <PCVideoTapDelegateProtocol> delegate;
    
    PCTimeDisplayController * timeDisplayController;
}

- (void)disengageController;

- (void)loadURL:(NSURL*)url withCallBack:(PCAVMovieReadyToPlay)callback;
- (CALayer*)layerToDisplay;

- (void)play;
- (void)pause;
- (void)stepForward;
- (void)stepBackward;

- (void)setRate:(float)nRate;

- (void)shouldForceUpdate:(BOOL)val;

#warning must implement these two
- (void)goToBeginning;
- (void)goToEnd;

- (void)goToFrame:(NSNumber*)frameNumber;
- (void)goToPercentage:(float)percentage;

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart;
- (unsigned long long)getTime;

- (void)saveCurrentTime;
- (void)restoreCurrentTime;
- (NSUInteger)currentFrame;

- (void)togglePlay;

- (void)addTimeObserver;
- (void)removeTimeObserver;
- (void)resize;

- (BOOL)isPlayerPlaying;

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCAVMovieReadyToPlay)callback;

@property (nonatomic, retain, readwrite) PCMoviePlayer * moviePlayer;
@property (nonatomic, retain, readwrite) VideoOutputLayer * videoOutputLayer;
@property (nonatomic, retain, readwrite) CATextLayer * timeDisplayLayer;
@property (nonatomic, retain, readwrite) id timeObserver;

@property (nonatomic, assign, readwrite) BOOL showTime;
@property (nonatomic, assign, readwrite) BOOL displayVerboseTime;

@property (nonatomic, retain, readwrite) NSString * identifier;

@property (nonatomic, assign, readwrite) id <PCVideoTapDelegateProtocol> videoTapDelegate;

@property (nonatomic, retain, readwrite) PCTimeDisplayController * timeDisplayController;


@end
