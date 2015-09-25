//
//  IOMoviePlayer.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/26/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOSurfaceLayer.h"
#import "TaskWrapper.h"
#import "PCProxyProtocol.h"

typedef void (^PCMovieReadyToPlayBlock)(BOOL ready);

@interface IOMoviePlayer : NSObject <TaskWrapperController>{
    id <PCProxyProtocol> movieProxy;
    NSSize movieSizeForView;
    IOSurfaceLayer *surfaceLayer;
    TaskWrapper * moviePlayer;
    BOOL helperIsReady;
    BOOL isPlaying;
    
    unsigned long long maxTimeValue;         //Max Time
    SInt32 nextInterestingDuration;          //Frame length
    float nominalFrameRate;
}


- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCMovieReadyToPlayBlock)callback;
- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCMovieReadyToPlayBlock)block;
- (NSString*)proxyMoviePath;

- (void)play;
- (void)pause;
- (oneway void)setMovieIsPlaying:(BOOL)flag;
- (void)goToBeginning;
- (void)goToEnd;
- (void)stepForward;
- (void)stepBackward;
- (oneway void)goToTimeValue:(long)timeValue;

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart;
- (unsigned long long)getTime;

- (void)goToFrame:(NSNumber*)frameNumber;
- (void)goToPercentage:(float)percentage;
- (oneway void)setMovieRate:(float)nRate;

- (unsigned long long)currentTimeValue;
- (NSUInteger)currentFrame;

- (void)launchHelperAsyncWithCallback:(PCMovieReadyToPlayBlock)block;

- (NSString*)currenTimeInfo;

@property (nonatomic, readwrite, retain) id movieProxy;
@property (nonatomic, readwrite, retain) IOSurfaceLayer *surfaceLayer;
@property (nonatomic, readwrite, assign) NSSize movieSizeForView;
@property (nonatomic, readwrite, assign) BOOL helperIsReady;
@property (nonatomic, readwrite, assign) BOOL isPlaying;

@property (nonatomic, readwrite, assign) unsigned long long maxTimeValue;
@property (nonatomic, readwrite, assign) SInt32 nextInterestingDuration;
@property (nonatomic, readwrite, assign) float nominalFrameRate;


@end
