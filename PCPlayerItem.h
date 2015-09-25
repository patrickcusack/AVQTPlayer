//
//  PCPlayerItem.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 7/11/14.
//  Copyright (c) 2014 Patrick Cusack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^PCPlayerItemIsLoaded)(id item, BOOL ready);

@interface PCPlayerItem : NSObject{
    AVPlayerItem * playerItem;
    BOOL loaded;
    
    PCPlayerItemIsLoaded readyBlock;
}

- (void)loadMovieFileWithPath:(NSString*)path;
- (void)loadMovieFileWithURL:(NSURL*)url;
- (void)loadMovieFileWithPath:(NSString*)path withReadyBlock:(PCPlayerItemIsLoaded)block;
- (void)loadMovieFileWithURL:(NSURL*)url withReadyBlock:(PCPlayerItemIsLoaded)block;

@property (nonatomic, assign, readwrite) BOOL loaded;
@property (nonatomic, retain, readwrite) AVPlayerItem * playerItem;
@property (nonatomic, copy, readwrite) PCPlayerItemIsLoaded readyBlock;

@end
