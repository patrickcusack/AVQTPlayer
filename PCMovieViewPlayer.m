//
//  PCMovieViewPlayer.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/10/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import "PCMovieViewPlayer.h"
#import "PCPlayerItem.h"

static void * KPCPlayerLayerReadyToPlay = &KPCPlayerLayerReadyToPlay;

@implementation PCMovieViewPlayer
@synthesize player;
@synthesize isPlaying;
@synthesize readyToPlay;
@synthesize timeObserver;
@synthesize readyBlock;

@synthesize videoAssetTimeScale;
@synthesize assetTimeScale;
@synthesize nominalFrameRate;
@synthesize naturalTimeScale;

@synthesize container;
@synthesize textLayer;
@synthesize playerLayer;
@synthesize shouldResizeWindowToMatch;

+ (PCMovieViewPlayer*)player{
    PCMovieViewPlayer * player = [[PCMovieViewPlayer alloc] init];
    [player constructPlayerLayer];
    
    return [player autorelease];
}

+ (PCMovieViewPlayer*)playerWithContainer:(PCMovieViewContainer*)nContainer{
    PCMovieViewPlayer * player = [[PCMovieViewPlayer alloc] init];
    [player setContainer:nContainer];
    [player constructPlayerLayer];
    
    return [player autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setIsPlaying:NO];
        [self setReadyToPlay:NO];
        [self setTextLayer:nil];
        [self setContainer:nil];
        [self setTimeObserver:nil];
        [self setPlayerLayer:nil];
        [self setPlayer:[[[AVPlayer alloc] init] autorelease]];
        [self setShouldResizeWindowToMatch:NO];
    }
    return self;
}

- (void)dealloc{
    
    if ([self timeObserver]) {
        [[self player] removeTimeObserver:[self timeObserver]];
        [self setTimeObserver:nil];
    }
    if (observerQueue) {
        CFRelease(observerQueue);
        observerQueue = nil;
    }
    
    if ([self textLayer]) {[[self textLayer] removeFromSuperlayer];}
    [self setPlayerLayer:nil];
    [self setPlayer:nil];
    [self setTextLayer:nil];
    [self setContainer:nil];
    
    [super dealloc];
}

- (void)addPlayerItemToPlayer:(AVPlayerItem*)playerItem{
    [self captureTimeRatesForPlayerItem:(AVPlayerItem*)playerItem];
    [[self player] replaceCurrentItemWithPlayerItem:playerItem];
    [self addObserver];
    
    if ([self container]) {
        [[self container] showSpinner];
    }
}

- (void)captureTimeRatesForPlayerItem:(AVPlayerItem*)playerItem{
    AVAsset * asset = [playerItem asset];
    
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0){
        
        NSArray * videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        
        if ([videoTracks count] > 0) {
            AVAssetTrack * track = [videoTracks objectAtIndex:0];
            [self setNaturalTimeScale:[track naturalTimeScale]];
            [self setNominalFrameRate:[track nominalFrameRate]];
            [self setVideoAssetTimeScale:[track naturalTimeScale]];
        }
    }
}

- (void)constructPlayerLayer{
    // Create an AVPlayerLayer and add it to the player view if there is video, but hide it until it's ready for display
    
    AVPlayerLayer *nPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
    [nPlayerLayer setBounds:NSRectToCGRect([[self container] bounds])];
    [nPlayerLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    [nPlayerLayer setHidden:YES];
    [nPlayerLayer addObserver:self
                   forKeyPath:@"readyForDisplay"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:KPCPlayerLayerReadyToPlay];
    
    [self setPlayerLayer:nPlayerLayer];
    
    [[self playerLayer] setBorderWidth:1.0];
    [[self playerLayer] setBorderColor:CGColorGetConstantColor(kCGColorWhite)];
    
    CGRect transformedBounds = [[self playerLayer] bounds];
    
    NSSize currentSize = NSSizeFromCGSize(transformedBounds.size);
    
    if ([self shouldResizeWindowToMatch]) {
        [[self container] resizeWindowWithContentSize:NSSizeFromCGSize(transformedBounds.size) animated:YES];
        float resizeHeight = currentSize.height / currentSize.width;
        [[[self container] window] setContentAspectRatio:NSMakeSize(1.0, resizeHeight)];
    } else {
        [[self playerLayer] setContentsGravity:AVLayerVideoGravityResizeAspect];
    }
    
    [[[self container] layer] addSublayer:[self playerLayer]];
    [[[self container] layer] setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)];
    
    [self positionInFrame:[[self container] bounds]];
    [(AVPlayerLayer*)[self playerLayer] setHidden:NO];
    
}

- (void)addObserver{
    
    if ([[self player] currentItem]) {

        if ([self textLayer]) {
            [[self textLayer] removeFromSuperlayer];
            [self setTextLayer:nil];
        }
        
        CATextLayer * nTextLayer = [self constructTextLayer];
        [self setTextLayer:nTextLayer];
        [[[self container] layer] insertSublayer:nTextLayer above:[self playerLayer]];
        
        if ([self timeObserver]) {
            [[self player] removeTimeObserver:[self timeObserver]];
            [self setTimeObserver:nil];
        }
        if (observerQueue) {
            CFRelease(observerQueue);
            observerQueue = nil;
        }

        observerQueue = dispatch_queue_create("timeObserverQueue", NULL);
        
        [self setTimeObserver:[[self player] addPeriodicTimeObserverForInterval:CMTimeMake(1, [self nominalFrameRate]) queue:observerQueue usingBlock:^(CMTime time){
            [self drawTimeToBeExanded];
        }]];
        
    }
}

- (void)drawTimeToBeExanded{
    
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    
    NSString * string = @"99:99:99:99 9999+99";
    
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
    [[self textLayer] setString:string];
    [[self textLayer] setBorderColor:blueColor];
    [[self textLayer] setBorderWidth:1.0];
    [CATransaction commit];
    
    CFRelease(whiteColor);
    CFRelease(redColor);
    CFRelease(blueColor);
    
}

- (CATextLayer*)constructTextLayer{
    
    CGColorRef clearColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0,1.0);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    
    CATextLayer * nTextLayer = [CATextLayer layer];
    [nTextLayer setBackgroundColor:clearColor];
    [nTextLayer setForegroundColor:whiteColor];
    [nTextLayer setShadowColor:shadowColor];
    
    [nTextLayer setShadowOffset:CGSizeMake(1, 1)];
    [nTextLayer setShadowOpacity:1.0];
    [nTextLayer setPosition:CGPointMake(0, 0)];
    [nTextLayer setBounds:CGRectMake(0, 0, [[self container] frame].size.width, 40)];
    [nTextLayer setAnchorPoint:CGPointMake(0.0, 0.0)];
    [nTextLayer setContentsGravity:kCAGravityBottom];//kCAGravityBottomLeft
    [nTextLayer setAutoresizingMask: kCALayerWidthSizable];
    [nTextLayer setAlignmentMode:kCAAlignmentCenter];
    
    CFRelease(clearColor);
    CFRelease(whiteColor);
    CFRelease(shadowColor);
    CFRelease(redColor);
    
    return nTextLayer;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context == KPCPlayerLayerReadyToPlay){
		if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES){
            [self setReadyToPlay:YES];
            
            if ([self container]) {
                [[self container] hideSpinner];
            }
            
            if(readyBlock){readyBlock(self, YES);}
		}
	}
}

- (void)addToContainer:(PCMovieViewContainer*)nContainer{
    /*assumes that the container view has a window*/
    [self setContainer:nContainer];
}

- (void)removeFromContainer{
    
    [[[self container] layer] setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 1.0)];
    
    [self pause];
    [[self playerLayer] setHidden:YES];
    [[self textLayer] removeFromSuperlayer];
    [[self playerLayer] removeFromSuperlayer];
    [self setContainer:nil];
    
    if ([self timeObserver]) {
        [[self player] removeTimeObserver:[self timeObserver]];
        [self setTimeObserver:nil];
    }
    if (observerQueue) {
        CFRelease(observerQueue);
        observerQueue = nil;
    }
}

- (void)positionInFrame:(NSRect)frame{
    [[self playerLayer] setPosition:CGPointMake(CGRectGetMidX(NSRectToCGRect(frame)), CGRectGetMidY(NSRectToCGRect(frame)))];
}


- (void)play{
    [[self player] play];
    [self setIsPlaying:YES];
}

- (void)pause{
    [[self player] pause];
    [self setIsPlaying:NO];
}

- (void)stepBackwards{
    
    if ([self isPlaying] == YES) {
        [self pause];
    }
    
    [[[self player] currentItem] stepByCount:-1];
}

- (void)stepFoward{
    
    if ([self isPlaying] == YES) {
        [self pause];
    }
    
    [[[self player] currentItem] stepByCount:1];
}

- (void)goToFrame:(NSNumber*)frameNumber{
    
    CMTime destinationTime = CMTimeMake(([self naturalTimeScale]/[self nominalFrameRate]) * [frameNumber integerValue], [self naturalTimeScale]);
    
    [[[self player] currentItem] seekToTime:destinationTime
                            toleranceBefore:kCMTimeZero
                             toleranceAfter:kCMTimeZero];
}


@end
