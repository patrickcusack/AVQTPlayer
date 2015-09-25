//
//  PCIOMovieController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/26/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCIOMovieController.h"
#import "PCGraphicsHelper.h"
#import "PCTCformatter.h"
#import "PCVideoStrings.h"
#import "ADRToolBoxLogger.h"

@interface PCIOMovieController(){
    NSTimer * _movieTimer;
    PCTCformatter *_formatter;
    unsigned long long _savedCurrentTime;
}
- (void)drawCurrentTime:(NSString*)timeString;
- (CATextLayer*)constructTextLayer;

@end

@implementation PCIOMovieController
@synthesize moviePlayer;
@synthesize videoOutputLayer;
@synthesize timeDisplayLayer;
@synthesize showTime;
@synthesize displayVerboseTime;
@synthesize identifier;
@synthesize timeDisplayController;

- (instancetype)init
{
    self = [super init];
    if (self) {

        IOMoviePlayer * player = [[[IOMoviePlayer alloc] init] autorelease];
        [self setMoviePlayer:player];
        IOSurfaceLayer * outputLayer = [[[IOSurfaceLayer alloc] init] autorelease];
        [outputLayer setBounds:CGRectMake(0, 0, 100, 100)];
        [self setVideoOutputLayer:outputLayer];
        [[self moviePlayer] setSurfaceLayer:outputLayer];
        
        _formatter = [[PCTCformatter genericPCTCformatter] retain];
        [self setShowTime:YES];
        [self setDisplayVerboseTime:YES];
        [self setIdentifier:@"Z"];
    }
    return self;
}

- (void)dealloc{
    [ADRToolBoxLogger addString:[NSString stringWithFormat:@"%@ %@ %@", [self class], NSStringFromSelector(_cmd), [self identifier]]];
    
    [self removeTimeObserver];
    
    [_formatter release];
    _formatter = nil;
    
    if ([self timeDisplayLayer]) {[[self timeDisplayLayer] removeFromSuperlayer];}
    [self setTimeDisplayLayer:nil];

    [self setVideoOutputLayer:nil];
    [self setMoviePlayer:nil];
    [self setIdentifier:nil];
    [self setTimeDisplayController:nil];
    
    [super dealloc];
}

- (void)disengageController{
    [ADRToolBoxLogger addString:[NSString stringWithFormat:@"%@ %@ %@", [self class], NSStringFromSelector(_cmd), [self identifier]]];
    [self pause];
    [self removeTimeObserver];
}

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCAVMovieReadyToPlay)callback{
    [[self moviePlayer] addAudioURLToCurrentVideoAsset:audioURL withCallBack:callback];
}

- (void)loadURL:(NSURL*)url withCallBack:(PCAVMovieReadyToPlay)callback{
    [self removeTimeObserver];
    
    __block IOMoviePlayer * weakMoviePlayer = [self moviePlayer];
    __block PCIOMovieController * weakSelf = self;
    
    [weakMoviePlayer loadMovieFileWithURL:url withReadyBlock:^(BOOL ready) {
        callback(ready);
        [weakSelf addTimeObserver];
    }];
}

- (NSString*)proxyMoviePath{
    return [[self moviePlayer] proxyMoviePath];
}

- (void)play{
    [[self moviePlayer] play];
}

- (void)pause{
    //[self updateTime]; // I disabled this as it caused issues when I closed down the VideoController
    [[self moviePlayer] pause];
}

- (void)goToBeginning{
    [[self moviePlayer] goToBeginning];
}

- (void)goToEnd{
    [[self moviePlayer] goToEnd];
}

- (void)stepForward{
    [[self moviePlayer] stepForward];
}

- (void)stepBackward{
    [[self moviePlayer] stepBackward];
}

- (void)setRate:(float)nRate{
    [[self moviePlayer] setMovieRate:nRate];
}

- (void)goToTimeValue:(long)timeValue{
    [[self moviePlayer] goToTimeValue:timeValue];
}

- (oneway void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart{
    [[self moviePlayer] goToTime:time withPictureStart:pictureStart];
}

- (unsigned long long)getTime{
    return [[self moviePlayer] getTime];
}

- (unsigned long long)currentTimeValue{
    return [[self moviePlayer] currentTimeValue];
}

- (void)goToFrame:(NSNumber*)frameNumber{
    [[self moviePlayer] goToFrame:frameNumber];
}

- (void)saveCurrentTime{
    _savedCurrentTime = [self currentTimeValue];
}

- (void)restoreCurrentTime{
    [[self moviePlayer] goToTimeValue:_savedCurrentTime];
}

- (NSUInteger)currentFrame{
    return [[self moviePlayer] currentFrame];
}

- (void)goToPercentage:(float)percentage{
    [[self moviePlayer] goToPercentage:percentage];
}

- (CALayer*)layerToDisplay{
    return (CALayer*)[self videoOutputLayer];
}

- (NSSize)movieSize{
    return [[self moviePlayer] movieSizeForView];
}

- (BOOL)isPlayerPlaying{
    return [[self moviePlayer] isPlaying];
}

- (void)launchHelperAsyncWithCallback:(PCMovieReadyToPlayBlock)block{
    [[self moviePlayer] launchHelperAsyncWithCallback:block];
}

- (void)addTimeObserver{
    
    CATextLayer * nTextLayer = [self constructTextLayer];
    [self setTimeDisplayLayer:nTextLayer];
    [[self layerToDisplay] addSublayer:nTextLayer];

    
    float denominator = [[self moviePlayer] nominalFrameRate];
    if (denominator < 1.0) {
        denominator = 1.0;
    }
    
    _movieTimer = [NSTimer scheduledTimerWithTimeInterval:1/denominator target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
}

- (void)removeTimeObserver{
    
    if (_movieTimer) {
        [_movieTimer invalidate];
        _movieTimer = nil;
    }
    
    if ([self timeDisplayLayer]) {
        [[self timeDisplayLayer] removeFromSuperlayer];
        [self setTimeDisplayLayer:nil];
    }

}

- (void)updateTime{
    
    if (![self timeDisplayLayer]) {
        return;
    }
    
    if ([self showTime] == NO) {
        [self drawCurrentTime:@""];
        return;
    }
    
    NSUInteger nInterestingDuration = [[self moviePlayer] nextInterestingDuration];
    if (nInterestingDuration == 0) {
        nInterestingDuration = 1;
    }
    
    NSUInteger currentFrame = (int)[[self moviePlayer] currentTimeValue] / nInterestingDuration;
    NSString * displayTime = @"";
    
    if ([self timeDisplayController]) {
        
        displayTime = [[self timeDisplayController] formattedStringForTotalFrames:currentFrame
                                                                 currentTimeValue:[[self moviePlayer] currentTimeValue]
                                                       andNextInterestingDuration:nInterestingDuration];        
    } else {
        
        if (_formatter) {
            NSString *tcString = [_formatter convertRawFramesToTimeCode:currentFrame withFrameBase:ceil([[self moviePlayer] nominalFrameRate])];
            NSString *ffString = [_formatter convertRawFramesToFeetAndFrames:currentFrame];
            NSString * filmTime = [NSString stringWithFormat:@" %@ %@", tcString, ffString];
            displayTime = filmTime;
        }
        
        if ([self displayVerboseTime] == YES) {
            NSString * verboseTime = [NSString stringWithFormat:@"%lld %lu %lu", [[self moviePlayer] currentTimeValue], (unsigned long)nInterestingDuration, (unsigned long)currentFrame];
            displayTime = [verboseTime stringByAppendingString:displayTime];
        }
    }
    
    [self drawCurrentTime:displayTime];
    
    float percentageComplete = [[self moviePlayer] currentTimeValue] * 1.0 / [[self moviePlayer] maxTimeValue];

    [[NSNotificationCenter defaultCenter] postNotificationName:KCURRENTPLAYBACKPOSITION
                                                        object:@{@"object":[NSNumber numberWithFloat:percentageComplete],
                                                                 @"identifier":[self identifier]}];
    
    if (percentageComplete > 0.999) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KPLAYBACKENDED
                                                            object:@{@"object":self, @"identifier":[self identifier]}];
    }
    
}

- (void)drawCurrentTime:(NSString*)timeString{
    
    if (timeString == nil) {
        timeString = @"99:99:99:99 9999+99";
    }
    
    __block PCIOMovieController * weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (![weakSelf timeDisplayLayer]) {
            return;
        }
        
        [CATransaction begin];
        [weakSelf sizeTextLayer:[weakSelf timeDisplayLayer] forString:timeString];
        [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
        [[weakSelf timeDisplayLayer] setString:timeString];
        [CATransaction commit];
    });
}

- (CATextLayer*)constructTextLayer{
    
    CGColorRef clearColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0,1.0);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    
    CATextLayer * nTextLayer = [CATextLayer layer];
    [nTextLayer setBackgroundColor:clearColor];
    [nTextLayer setForegroundColor:whiteColor];
    [nTextLayer setShadowColor:shadowColor];
    [nTextLayer setFontSize:20.0];
    
    [nTextLayer setShadowOffset:CGSizeMake(1, 1)];
    [nTextLayer setShadowOpacity:1.0];
    [nTextLayer setPosition:CGPointMake(0, 0)];
    [nTextLayer setBounds:CGRectMake(0, 0, [[self videoOutputLayer] bounds].size.width, 60)];
    [nTextLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
    [nTextLayer setContentsGravity:kCAGravityBottom];//kCAGravityBottomLeft
    [nTextLayer setAutoresizingMask: kCALayerWidthSizable];
    [nTextLayer setAlignmentMode:kCAAlignmentCenter];
    [nTextLayer setContentsScale:2.0];
//    [nTextLayer setBorderWidth:1.0];
//    [nTextLayer setBorderColor:redColor];
    
    CFRelease(clearColor);
    CFRelease(whiteColor);
    CFRelease(shadowColor);
    CFRelease(redColor);
    CFRelease(blueColor);
    
    return nTextLayer;
}

- (void)sizeTextLayer:(CATextLayer*)nLayer forString:(NSString*)nString{
    
    if (!nLayer || [nString isEqualToString:@""]) {
        return;
    }
    
    NSSize size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:[nLayer fontSize]]}];
    CGFloat currentFontSize = [nLayer fontSize];
    
    if (size.width < ([nLayer bounds].size.width * 0.8)) {
        while (size.width < ([nLayer bounds].size.width * 0.8) && currentFontSize < 21.0) {
            
            currentFontSize += 1.0;
            
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [nLayer setBounds:CGRectMake(0, 0, [nLayer bounds].size.width, currentFontSize * 1.3)];
            [CATransaction commit];
        
        }
        
        return;
    }
    
    if (size.width > [nLayer bounds].size.width * 0.9) {
        while (size.width > [nLayer bounds].size.width * 0.9 && currentFontSize > 8.0 ) {
            currentFontSize -= 1.0;
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [nLayer setBounds:CGRectMake(0, 0, [nLayer bounds].size.width, currentFontSize * 1.3)];
            [CATransaction commit];
        }
        
        return;
    }
    
}

@end
