//
//  PCMovieControllerProxy.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/29/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef void (^PCAVMovieReadyToPlay)(BOOL ready);

@protocol PCMovieControllerProxy <NSObject>

- (void)disengageController;

- (void)loadURL:(NSURL*)url withCallBack:(PCAVMovieReadyToPlay)callback;
- (CALayer*)layerToDisplay;
- (void)setShowTime:(BOOL)shouldShowTime;

- (void)play;
- (void)pause;
- (void)stepForward;
- (void)stepBackward;

- (void)setRate:(float)nRate;

- (void)goToBeginning;
- (void)goToEnd;

/*These time values are normalized against a 48kHz time base*/
- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart;
- (unsigned long long)getTime;

- (void)goToFrame:(NSNumber*)frameNumber;
- (void)goToPercentage:(float)percentage;

- (void)saveCurrentTime;
- (void)restoreCurrentTime;
- (NSUInteger)currentFrame;

- (BOOL)isPlayerPlaying;

- (NSSize)movieSize;

@optional

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCAVMovieReadyToPlay)callback;
- (void)addTimeObserver;
- (void)removeTimeObserver;

@end
