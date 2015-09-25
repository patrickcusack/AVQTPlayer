
//
//  Created by patrick cusack on 4/15/2015.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PCProxyProtocol

- (oneway void)addMovieURL:(NSURL*)movieURL;
- (oneway void)openMovieURL:(NSURL*)movieURL;
- (oneway void)addAudioFileToCurrentMovie:(NSURL*)audioURL;
- (NSString*)proxyMoviePath;

#pragma mark - setters for movie properties
- (void)play;
- (void)pause;
- (oneway void)setMovieIsPlaying:(BOOL)flag;
- (void)goToBeginning;
- (void)goToEnd;
- (void)stepForward;
- (void)stepBackward;
- (oneway void)goToTimeValue:(long)timeValue;
- (oneway void)setMovieRate:(float)nRate;

#pragma mark - getters for movie properties
-(BOOL)hasMovie;
-(BOOL)audioHasLoaded;
-(BOOL)isMoviePlaying;
-(long long)currentTimeValue;
-(long long)maxTimeValue;
-(long)timeScale;
-(NSValue*)movieSize;
-(SInt32)nextInterestingDuration;
-(float)nominalFrameRate;

#pragma mark - cleanup
- (oneway void) quitHelperTool;

@end
