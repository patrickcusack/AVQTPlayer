//
//  PCIOMovieController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/26/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCMovieControllerProxy.h"
#import "IOMoviePlayer.h"
#import "IOSurfaceLayer.h"
#import "PCMovieControllerProxy.h"
#import "PCTimeDisplayController.h"

//typedef void (^PCAVMovieReadyToPlay)(BOOL ready);

@interface PCIOMovieController : NSObject <PCMovieControllerProxy>{
    IOMoviePlayer * moviePlayer;
    IOSurfaceLayer * videoOutputLayer;
    CATextLayer * timeDisplayLayer;
    
    BOOL showTime;
    BOOL displayVerboseTime;
    
    NSString * identifier;
    
    PCTimeDisplayController * timeDisplayController;
}

- (void)disengageController;

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCAVMovieReadyToPlay)callback;
- (void)loadURL:(NSURL*)url withCallBack:(PCAVMovieReadyToPlay)callback;
- (NSString*)proxyMoviePath;

- (CALayer*)layerToDisplay;

- (void)play;
- (void)pause;
- (void)stepForward;
- (void)stepBackward;

- (void)setRate:(float)nRate;

- (void)goToBeginning;
- (void)goToEnd;

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart;
- (unsigned long long)getTime;

- (void)goToFrame:(NSNumber*)frameNumber;
- (void)goToPercentage:(float)percentage;

- (void)saveCurrentTime;
- (void)restoreCurrentTime;

- (NSUInteger)currentFrame;

- (void)goToTimeValue:(long)timeValue;
- (unsigned long long)currentTimeValue;

- (void)addTimeObserver;
- (void)removeTimeObserver;

- (BOOL)isPlayerPlaying;

- (void)launchHelperAsyncWithCallback:(PCMovieReadyToPlayBlock)block;

- (NSSize)movieSize;

@property (nonatomic, retain, readwrite) IOMoviePlayer * moviePlayer;
@property (nonatomic, retain, readwrite) IOSurfaceLayer * videoOutputLayer;
@property (nonatomic, retain, readwrite) CATextLayer * timeDisplayLayer;

@property (nonatomic, assign, readwrite) BOOL showTime;
@property (nonatomic, assign, readwrite) BOOL displayVerboseTime;

@property (nonatomic, retain, readwrite) NSString * identifier;

@property (nonatomic, retain, readwrite) PCTimeDisplayController * timeDisplayController;

@end
