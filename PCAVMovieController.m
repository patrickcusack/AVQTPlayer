//
//  PCAVMovieController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/12/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCAVMovieController.h"
#import "PCTCformatter.h"
#import "PCVideoStrings.h"

@interface PCAVMovieController (){
    PCTCformatter *_formatter;
    CMTime _savedCurrentTime;
}
- (void)drawCurrentTime:(NSString*)timeString;
- (CATextLayer*)constructTextLayer;
@end

@implementation PCAVMovieController
@synthesize moviePlayer;
@synthesize videoOutputLayer;
@synthesize timeDisplayLayer;
@synthesize timeObserver;
@synthesize showTime;
@synthesize displayVerboseTime;
@synthesize identifier;
@synthesize videoTapDelegate;
@synthesize timeDisplayController;

- (instancetype)init{
    
    self = [super init];
    if (self) {
        PCMoviePlayer * player = [[[PCMoviePlayer alloc] init] autorelease];
        [self setMoviePlayer:player];
        VideoOutputLayer * videoLayer = [[[VideoOutputLayer alloc] init] autorelease];
        [self setVideoOutputLayer:videoLayer];
        
        _formatter = [[PCTCformatter genericPCTCformatter] retain];
        [self setShowTime:YES];
        [self setDisplayVerboseTime:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackFinished)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        [self setIdentifier:@"Z"];
        [self setVideoTapDelegate:nil];

    }
    return self;
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if ([self timeObserver]) {
        [[[self moviePlayer] player] removeTimeObserver:[self timeObserver]];
        [self setTimeObserver:nil];
    }
    
    if (observerQueue) {
        CFRelease(observerQueue);
        observerQueue = nil;
    }
    
    [_formatter release];
    _formatter = nil;
    
    if ([self timeDisplayLayer]) {[[self timeDisplayLayer] removeFromSuperlayer];}
    [self setTimeDisplayLayer:nil];
    
    [self setMoviePlayer:nil];
    [self setVideoOutputLayer:nil];
    
    [self setIdentifier:nil];
    [self setVideoTapDelegate:nil];
    [self setTimeDisplayController:nil];
    
    [super dealloc];
}

- (void)setVideoTapDelegate:(id<PCVideoTapDelegateProtocol>)nVideoTapDelegate{
    videoTapDelegate = nVideoTapDelegate;
    [[self videoOutputLayer] setVideoTapDelegate:nVideoTapDelegate];
}

- (void)disengageController{
    [self pause];
    [self removeTimeObserver];
}

- (void)loadURL:(NSURL*)url withCallBack:(PCAVMovieReadyToPlay)callback{
    
    __block VideoOutputLayer * weakOutputLayer = [self videoOutputLayer];
    __block PCAVMovieController * weakAVController = self;
    __block PCMoviePlayer * weakMoviePlayer = [self moviePlayer];
    
    [self removeTimeObserver];
    [weakOutputLayer removeCurrentPlayer:[self moviePlayer]];

    [weakMoviePlayer loadMovieFileWithURL:url withReadyBlock:^(BOOL ready) {
        [weakOutputLayer addPlayer:weakMoviePlayer];
        [weakAVController addTimeObserver];
        callback(ready);
    }];

}

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL withCallBack:(PCAVMovieReadyToPlay)callback{
    
    __block VideoOutputLayer * weakOutputLayer = [self videoOutputLayer];
    __block PCMoviePlayer * weakMoviePlayer = [self moviePlayer];
    __block PCAVMovieController * weakAVController = self;
    
    [self removeTimeObserver];
    [weakOutputLayer removeCurrentPlayer:weakMoviePlayer];
    
    [[self moviePlayer] addAudioURLToCurrentVideoAsset:audioURL withReadyBlock:^(BOOL ready) {
        [weakOutputLayer addPlayer:weakMoviePlayer];
        [weakAVController addTimeObserver];
        callback(ready);
    }];
}

- (void)shouldForceUpdate:(BOOL)val{
    [[self videoOutputLayer] setForceUpdate:val];
}

- (CALayer*)layerToDisplay{
    return (CALayer*)[self videoOutputLayer];
}

- (void)togglePlay{
    [[self moviePlayer] togglePlay];
}

- (void)play{
    [[self moviePlayer] play];
}

- (void)pause{
    [[self moviePlayer] pause];
}

- (void)stepForward{
    [[self moviePlayer] stepForward];
}

- (void)stepBackward{
    [[self moviePlayer] stepBackward];
}

- (void)setRate:(float)nRate{
    [[self moviePlayer] setRate:nRate];
}

- (void)goToBeginning{
    [[self moviePlayer] goToPercentage:0.0];
}

- (void)goToEnd{
    [[self moviePlayer] goToPercentage:1.0];
}

- (void)goToFrame:(NSNumber*)frameNumber{
    [[self moviePlayer] goToFrame:frameNumber];
}

- (void)goToPercentage:(float)percentage{
    [[self moviePlayer] goToPercentage:percentage];
}

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart{
    [[self moviePlayer] goToTime:time withPictureStart:(NSNumber*)pictureStart];
}

- (unsigned long long)getTime{
    return [[self moviePlayer] getTime];
}

- (void)saveCurrentTime{
    _savedCurrentTime = [[self moviePlayer] currentPlayerTime];
}

- (void)restoreCurrentTime{
    [[self moviePlayer] goToTime:_savedCurrentTime];
}

- (NSUInteger)currentFrame{
    return [[self moviePlayer] currentFrame];
}

- (void)playbackFinished{
    [[NSNotificationCenter defaultCenter] postNotificationName:KPLAYBACKENDED
                                                        object:@{@"object":self, @"identifier":[self identifier]}];

}

- (NSSize)movieSize{
    return NSSizeFromCGSize([[self moviePlayer] sizeOfVideoTrack]);
}

- (void)resize{
    [self drawCurrentTime:[[self timeDisplayLayer] string]];
}

- (BOOL)isPlayerPlaying{
    return [[self moviePlayer] isPlaying];
}

#pragma mark -

- (void)removeTimeObserver{
    
    if ([[self moviePlayer] playerItem]) {
        
        if ([self timeDisplayLayer]) {
            [[self timeDisplayLayer] removeFromSuperlayer];
            [self setTimeDisplayLayer:nil];
        }
        
        if ([self timeObserver]) {
            [[[self moviePlayer] player] removeTimeObserver:[self timeObserver]];
            [self setTimeObserver:nil];
        }
        if (observerQueue) {
            CFRelease(observerQueue);
            observerQueue = nil;
        }
   
    }
}

- (void)addTimeObserver{
    
    if ([[self moviePlayer] playerItem]) {
        
        CATextLayer * nTextLayer = [self constructTextLayer];
        [self setTimeDisplayLayer:nTextLayer];
        [[self layerToDisplay] addSublayer:nTextLayer];
        
        NSString * observerName = [NSString stringWithFormat:@"timeObserverQueue_%@", [self identifier]];
        
        observerQueue = dispatch_queue_create([observerName UTF8String], NULL);
        
        __block PCAVMovieController * weakSelf = self;
        
        [self setTimeObserver:[[[self moviePlayer] player] addPeriodicTimeObserverForInterval:CMTimeMake(1, [[self moviePlayer] nominalFrameRate]) queue:observerQueue usingBlock:^(CMTime time){
            
            if ([self showTime] == NO) {
                return;
            }
            
            CMTime currentPlayerItemTime = CMTimeConvertScale(time, [[weakSelf moviePlayer] naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
            CMTime duration = CMTimeConvertScale([[weakSelf moviePlayer] duration], [[weakSelf moviePlayer] naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
            
            CMTimeValue currentTime         = currentPlayerItemTime.value;
            CMTimeScale currentTimeScale    = currentPlayerItemTime.timescale;
            NSUInteger currentFrame         = currentPlayerItemTime.value/[[self moviePlayer] frameSize];
            
            NSString * displayTime = @"";
            
            
            if ([self timeDisplayController]) {
                
                displayTime = [[self timeDisplayController] formattedStringForTotalFrames:currentFrame
                                                                         currentTimeValue:currentTime
                                                               andNextInterestingDuration:currentTimeScale];
            } else {
                if (_formatter) {
                    NSString *tcString = [_formatter convertRawFramesToTimeCode:currentFrame withFrameBase:ceil([[self moviePlayer] nominalFrameRate])];
                    NSString *ffString = [_formatter convertRawFramesToFeetAndFrames:currentFrame];
                    NSString * filmTime = [NSString stringWithFormat:@" %@ %@", tcString, ffString];
                    displayTime = filmTime;
                }
                
                if ([self displayVerboseTime] == YES) {
                    NSString * verboseTime = [NSString stringWithFormat:@"%lld %d %lu", currentTime, currentTimeScale, (unsigned long)currentFrame];
                    displayTime = [verboseTime stringByAppendingString:displayTime];
                }
            }
            
            
            [weakSelf drawCurrentTime:displayTime];
            
            float percentageComplete = (currentPlayerItemTime.value * 1.0) / duration.value;
            [[NSNotificationCenter defaultCenter] postNotificationName:KCURRENTPLAYBACKPOSITION
                                                                object:@{@"object":[NSNumber numberWithFloat:percentageComplete],
                                                                         @"identifier":[self identifier]}];
        }]];
        
    }
}

- (void)drawCurrentTime:(NSString*)timeString{
    
    if (timeString == nil) {
        timeString = @"99:99:99:99 9999+99";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [self sizeTextLayer:[self timeDisplayLayer] forString:timeString];
        [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
        [[self timeDisplayLayer] setString:timeString];
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
    
    if (!nLayer) {
        return;
    }
    
    NSSize size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:[nLayer fontSize]]}];
    CGFloat currentFontSize = [nLayer fontSize];
    
    if (size.width < ([nLayer bounds].size.width * 0.8)) {
        while (size.width < ([nLayer bounds].size.width * 0.8) && currentFontSize < 21.0) {
            
            currentFontSize += 1.0;
            
            if (currentFontSize > 20) {
                currentFontSize = 20;
            }
            
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [nLayer setBounds:CGRectMake(0, 0, [nLayer bounds].size.width, currentFontSize * 1.3)];
            [CATransaction commit];
            
            if (currentFontSize == 20) {
                break;
            }
        }
        
        return;
    }
    
    if (size.width > [nLayer bounds].size.width * 0.9) {
        while (size.width > [nLayer bounds].size.width * 0.9 && currentFontSize > 8.0) {
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
