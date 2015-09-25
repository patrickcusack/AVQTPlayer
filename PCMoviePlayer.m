//
//  PCMovieBasePlayer.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/1/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCMoviePlayer.h"
#import "PCPlayerItem.h"

NSString * NSStringFromCMTime(CMTime time){
    return [NSString stringWithFormat:@"%lld %d", time.value, time.timescale];
}

@implementation PCMoviePlayer
@synthesize player;
@synthesize isPlaying;
@synthesize readyToPlay;
@synthesize readyBlock;
@synthesize duration;

@synthesize videoAssetTimeScale;
@synthesize assetTimeScale;
@synthesize nominalFrameRate;
@synthesize naturalTimeScale;

@synthesize playerItem;

@synthesize shouldResizeWindowToMatch;
@synthesize currentAsset;
@synthesize currentURL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setIsPlaying:NO];
        [self setReadyToPlay:NO];
        [self setPlayer:[[[AVPlayer alloc] init] autorelease]];
        
        [[self player] addObserver:self
                     forKeyPath:@"status"
                        options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                        context:nil];
        
        [self setCurrentURL:nil];
    }
    return self;
}

- (void)dealloc{

    [self setCurrentURL:nil];
    [self setCurrentAsset:nil];
    [[self player] removeObserver:self forKeyPath:@"status"];
    
    if ([self readyBlock]) {
        [self setReadyBlock:nil];
    }
    
    [[self player] replaceCurrentItemWithPlayerItem:nil];
    [self setPlayerItem:nil];
    [self setPlayer:nil];
    
    [super dealloc];
}

- (void)addPlayerItemToPlayer:(AVPlayerItem*)nPlayerItem{
    [self captureTimeRatesForPlayerItem:(AVPlayerItem*)nPlayerItem];
    [[self player] replaceCurrentItemWithPlayerItem:nPlayerItem];
}

- (void)addPlayerItemToPlayer:(AVPlayerItem*)nPlayerItem withCallBack:(PCMovieReadyToPlayBlock)block{
    [self captureTimeRatesForPlayerItem:(AVPlayerItem*)nPlayerItem];
    [[self player] replaceCurrentItemWithPlayerItem:nPlayerItem];
    
    if (block) {
        block(YES);
    }
}

- (void)captureTimeRatesForPlayerItem:(AVPlayerItem*)nPlayerItem{
    AVAsset * asset = [nPlayerItem asset];
    
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


- (CMTimeValue)frameSize{
    return (CMTimeValue)([self naturalTimeScale]/[self nominalFrameRate]);
}

- (AVPlayerItem*)playerItem{
    if ([self player] && [[self player] currentItem]) {
        return [[self player] currentItem];
    }
    return nil;
}

- (CGSize)sizeOfVideoTrack{
    
    if ([self playerItem]) {
        AVAsset * asset = [[self playerItem] asset];
        
        if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0){
            
            NSArray * videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            
            if ([videoTracks count] > 0) {
                AVAssetTrack * track = [videoTracks objectAtIndex:0];
                return [track naturalSize];
            }
        }
    }
    
    return CGSizeZero;
}

#pragma mark -
#pragma mark Transport
#pragma mark -

- (void)togglePlay{
    if ([self isPlaying]) {
        [[self player] pause];
        [self setIsPlaying:NO];
    } else {
        [[self player] play];
        [self setIsPlaying:YES];
    }
}

- (void)play{
    [[self player] play];
    [self setIsPlaying:YES];
}

- (void)pause{
    [[self player] pause];
    [self setIsPlaying:NO];
}

- (void)stepBackward{
    
    if ([self isPlaying] == YES) {
        [self pause];
    }
    
    CMTime nextTime  = CMTimeConvertScale([[[self player] currentItem] currentTime], [self naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
    nextTime.value -= [self frameSize];
    
    [[[self player] currentItem] seekToTime:nextTime
                            toleranceBefore:kCMTimeZero
                             toleranceAfter:kCMTimeZero];
}

- (void)stepForward{
    
    if ([self isPlaying] == YES) {
        [self pause];
    }
    
    CMTime nextTime  = CMTimeConvertScale([[[self player] currentItem] currentTime], [self naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
    nextTime.value += [self frameSize];
    
    [[[self player] currentItem] seekToTime:nextTime
                            toleranceBefore:kCMTimeZero
                             toleranceAfter:kCMTimeZero];
    
}

- (void)setRate:(float)nRate{
    if ([self player]) {
        [[self player] setRate:nRate];
    }
}

- (void)goToFrame:(NSNumber*)frameNumber{
    
    if ([self player] && [[self player] currentItem]) {
        
        NSUInteger frameLength = ([self naturalTimeScale]/[self nominalFrameRate]);
        CMTime destinationTime = CMTimeMake(frameLength * [frameNumber integerValue], [self naturalTimeScale]);
        
        [[[self player] currentItem] seekToTime:destinationTime
                                toleranceBefore:kCMTimeZero
                                 toleranceAfter:kCMTimeZero];
    }
}

- (void)goToPercentage:(float)percentage{

    if ([self player] && [[self player] currentItem]) {
        
        CMTimeScale nValue = percentage * [self duration].value;
        CMTime destinationTime = [self duration];
        destinationTime.value = nValue;

        [[[self player] currentItem] seekToTime:destinationTime
                                toleranceBefore:kCMTimeZero
                                 toleranceAfter:kCMTimeZero];
    }
}

- (void)goToTime:(CMTime)nTime{
    
    if ([self player] && [[self player] currentItem]) {
        
        [[[self player] currentItem] seekToTime:nTime
                                toleranceBefore:kCMTimeZero
                                 toleranceAfter:kCMTimeZero];
    }
}

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart{
    
    if ([self player] && [[self player] currentItem]) {
        
        int effectiveFrameRate = ceil([self nominalFrameRate]);
        unsigned long long totalFrames = 0;
        
        switch (effectiveFrameRate) {
            case 24:
                totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 2000;
                break;
            case 25:
                totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 1920;
                break;
            default:
                totalFrames = ([time unsignedLongLongValue] - [pictureStart unsignedLongLongValue]) / 1600;
        }
    
        [self goToFrame:[NSNumber numberWithUnsignedLongLong:totalFrames]];
    }
    
}

- (NSUInteger)getTime{
    
    int effectiveFrameRate = ceil([self nominalFrameRate]);
    
    switch (effectiveFrameRate) {
        case 24:
            return [self currentFrame] * 2000;
            break;
        case 25:
            return [self currentFrame] * 1920;
            break;
        default:
            return [self currentFrame] * 1600;
    }
    
    return 0;
}

- (CMTime)currentPlayerTime{
    CMTime time = [[[self player] currentItem] currentTime];
    return  CMTimeConvertScale(time, [self naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
}

- (NSString*)currentPlayerTimeString{
    return NSStringFromCMTime([self currentPlayerTime]);
}

- (NSUInteger)currentFrame{
    CMTime currentTime = [[self playerItem] currentTime];
    CMTime currentPlayerItemTime = CMTimeConvertScale(currentTime, [self naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
    return currentPlayerItemTime.value/[self frameSize];
}

#pragma mark -
#pragma mark Player Item Loading
#pragma mark -

- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCMovieReadyToPlayBlock)block{
    
    [self setCurrentURL:url];
    [self setCurrentAsset:[AVAsset assetWithURL:url]];
    [self loadAsset:[self currentAsset]];
    [self setReadyBlock:block];
}

- (void)addAudioURLToCurrentVideoAsset:(NSURL *)audioURL withReadyBlock:(PCMovieReadyToPlayBlock)block{
    
    AVMutableComposition * mComposition = [AVMutableComposition composition];
    AVAsset * videoAsset = [self currentAsset];
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    
    AVMutableCompositionTrack* videoTrack= [mComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError* error = nil;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];

    if (error) {
        NSLog(@"Audio URL %@ videoTrack insertTimeRange: %@", audioURL, [error localizedDescription]);
        return;
    }
    
    error = nil;
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                        ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];

    if (error) {
        NSLog(@"Audio URL %@ audioTrack insertTimeRange: %@", audioURL, [error localizedDescription]);
        return;
    }

    AVComposition * composition = [[mComposition copy] autorelease];
    [self loadAsset:composition];
    
    [self setReadyBlock:^(BOOL ready){
        if(ready == YES){
            block(ready);
        }
    }];

    
}

- (void)addAudioURLToCurrentVideoAsset:(NSURL*)audioURL error:(NSError**)err{
    
    AVMutableComposition * mComposition = [AVMutableComposition composition];
    AVAsset * videoAsset = [self currentAsset];
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    
    AVMutableCompositionTrack* videoTrack= [mComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack* audioTrack = [mComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError* error = nil;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];
    *err = error;
    
    if (error) {
        return;
    }
    
    error = nil;
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                        ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0]
                         atTime:kCMTimeZero
                          error:&error];
    *err = error;
    
    if (error) {
        return;
    }
    
    __block PCMoviePlayer * weakSelf = self;
    CMTime cPlayerTime = [self currentPlayerTime];
    
    AVComposition * composition = [[mComposition copy] autorelease];
    [self loadAsset:composition];
    [self setReadyBlock:^(BOOL ready){
        [weakSelf goToTime:cPlayerTime];
    }];
    
}

- (void)loadAsset:(AVAsset*)asset{
    
    NSArray * keysToLoad = @[@"tracks"];
    
    __block PCMoviePlayer * weakSelf = self;
    
    [asset loadValuesAsynchronouslyForKeys:keysToLoad completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleKeysToLoad:keysToLoad forAsset:asset];
        });
    }];
    
}

- (void)setPlayerItem:(AVPlayerItem *)nPlayerItem{
    
    [playerItem removeObserver:self forKeyPath:@"status"];
    
    [nPlayerItem retain];
    [playerItem release];
    playerItem = nPlayerItem;
    
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                    context:nil];
}

- (void)handleKeysToLoad:(NSArray*)keys forAsset:(AVAsset*)asset{
    
    for (NSString * key in keys) {
        NSError * e = nil;
        if ([asset statusOfValueForKey:key error:&e] == AVKeyValueStatusFailed) {
            
            if ([self readyBlock]) {
                PCMovieReadyToPlayBlock block = [self readyBlock];
                block(NO);
                [self setReadyBlock:nil];
            }
            
            return;
            
        } else if ([asset statusOfValueForKey:key error:&e] == AVKeyValueStatusLoaded){
            
            if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0){
                
                AVPlayerItem *nPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                
                if (nPlayerItem) {
                    [self loadPlayerItem:nPlayerItem];
                    return;
                }

            }
            
        }
    }
    
    if ([self readyBlock]) {
        PCMovieReadyToPlayBlock block = [self readyBlock];
        block(NO);
        [self setReadyBlock:nil];
    }
    
}

- (void)loadPlayerItem:(AVPlayerItem*)nPlayerItem{
    
    [self setPlayerItem:nPlayerItem];
    [self addPlayerItemToPlayer:nPlayerItem];
    
    [self setReadyToPlay:YES];
    if ([self readyBlock]) {
        PCMovieReadyToPlayBlock block = [self readyBlock];
        block(YES);
        [self setReadyBlock:nil];
    }
    
    return;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([object isKindOfClass:[AVPlayerItem class]] && [keyPath isEqualToString:@"status"]) {
        
        AVPlayerItem *nPlayerItem = (AVPlayerItem *)object;
        if([nPlayerItem status] == AVPlayerItemStatusReadyToPlay){
            [nPlayerItem setAudioTimePitchAlgorithm:AVAudioTimePitchAlgorithmVarispeed];
            [self setDuration:[nPlayerItem duration]];
        }
        
    }
    
}


@end
