//
//  MultiMovieRenderer.h
//  IOSurfaceTest2
//
//  Created by Patrick Cusack on 5/7/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreVideo/CoreVideo.h>

// For OSAtomic operations
#import <libkern/OSAtomic.h>

//#define	DISABLE_IOSURFACE

#import "PCProxyProtocol.h"

#if defined(DISABLE_IOSURFACE) && defined(COREVIDEO_SUPPORTS_IOSURFACE)
#undef COREVIDEO_SUPPORTS_IOSURFACE
#define COREVIDEO_SUPPORTS_IOSURFACE	0
#endif

@class PCMovieRenderObject;

@interface MultiMovieRenderer : NSObject <NSApplicationDelegate, PCProxyProtocol>{

    NSTimeInterval						refHostTime;

    NSString                            *doUUID;
    pid_t                               _parentID;
    NSConnection                        *_theConnection;
    NSTimer                             *_pollParentTimer;
    
    NSFileHandle                        *standardOut;
    NSTimeInterval                      timing;
    
    CVDisplayLinkRef                    displayLink;
    CGDirectDisplayID                   mainDisplayID;
    
    PCMovieRenderObject                 *movieA;
}

- (oneway void)addMovieURL:(NSURL*)movieURL;
- (oneway void)addAudioFileToCurrentMovie:(NSURL*)audioURL;
- (NSString*)proxyMoviePath;

- (void)play;
- (void)pause;
- (oneway void)setMovieIsPlaying:(BOOL)flag;
- (void)goToBeginning;
- (void)goToEnd;
- (void)stepForward;
- (void)stepBackward;
- (oneway void)goToTimeValue:(long)timeValue;
- (oneway void)setMovieRate:(float)nRate;

- (long long)currentTimeValue;
- (long long)maxTimeValue;
- (long)timeScale;

- (BOOL)hasMovie;
- (BOOL)audioHasLoaded;
- (BOOL)isMoviePlaying;

- (NSValue*)movieSize;

- (NSString *)moviePath;
- (NSTimeInterval)movieDuration;
- (NSTimeInterval)frameStep;
- (SInt32)nextInterestingDuration;
- (float)movieFrameRate;
- (float)nominalFrameRate;
- (NSTimeInterval)queuedMovieTime;

- (void)setMovieRate: (float)aFloat;
- (NSTimeInterval)movieTime;
- (void)setMovieTime: (NSTimeInterval)aDouble;

- (void)getFrameDisplayLink:(double)nTime;

@property (nonatomic, retain, readwrite) NSString * doUUID;
@property (nonatomic, retain, readwrite) NSFileHandle * standardOut;
@property (nonatomic, retain, readwrite) PCMovieRenderObject *movieA;

@end
