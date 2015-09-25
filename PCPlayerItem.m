//
//  PCPlayerItem.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/11/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import "PCPlayerItem.h"

@implementation PCPlayerItem
@synthesize playerItem;
@synthesize loaded;
@synthesize readyBlock;


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setLoaded:NO];
    }
    return self;
}

- (void)dealloc{
    if ([self readyBlock]) {
        [self setReadyBlock:nil];
    }
    [self setPlayerItem:nil];
    [super dealloc];
}

- (void)loadMovieFileWithPath:(NSString*)path{
    [self loadMovieFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void)loadMovieFileWithURL:(NSURL*)url{
    [self loadAsset:[AVAsset assetWithURL:url]];
}

- (void)loadMovieFileWithPath:(NSString*)path withReadyBlock:(PCPlayerItemIsLoaded)block{
    [self loadAsset:[AVAsset assetWithURL:[NSURL fileURLWithPath:path]]];
    [self setReadyBlock:block];
}

- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCPlayerItemIsLoaded)block{
    [self loadAsset:[AVAsset assetWithURL:url]];
    [self setReadyBlock:block];
}

- (void)loadAsset:(AVAsset*)asset{
    
    NSArray * keysToLoad = @[@"tracks"];
    
    [asset loadValuesAsynchronouslyForKeys:keysToLoad completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleKeysToLoad:keysToLoad forAsset:asset];
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
                PCPlayerItemIsLoaded block = [self readyBlock];
                block(nil, NO);
            }
            
            return;
            
        } else if ([asset statusOfValueForKey:key error:&e] == AVKeyValueStatusLoaded){
        
            if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0){
                AVPlayerItem *nPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                if (nPlayerItem) {
                    [self setPlayerItem:nPlayerItem];
                    [self setLoaded:YES];
                    
                    if ([self readyBlock]) {
                        PCPlayerItemIsLoaded block = [self readyBlock];
                        block(playerItem, YES);
                    }
                }
                
                return;
            }
            
        }
    }

    if ([self readyBlock]) {
        PCPlayerItemIsLoaded block = [self readyBlock];
        block(nil, NO);
    }
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([object isKindOfClass:[AVPlayerItem class]] && [keyPath isEqualToString:@"status"]) {
        
        AVPlayerItem *nPlayerItem = (AVPlayerItem *)object;
        
        if([nPlayerItem status] == AVPlayerItemStatusReadyToPlay){
            [nPlayerItem setAudioTimePitchAlgorithm:AVAudioTimePitchAlgorithmVarispeed];
        }
    
    }
}



@end
