//
//  PCVideoController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/10/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "PCKeyControllerDelegate.h"
#import "PCDragViewControllerDelegate.h"
#import "PCTransportDelegateProcotol.h"
#import "PCMovieControllerProxy.h"
#import "PCVideoTapDelegateProtocol.h"
#import "PCTransportDelegateProcotol.h"
#import "PCTimeDisplayController.h"

@class PCAVMovieController;
@class PCIOMovieController;
@class PCVideoTransport;
@class PCVideoController;

typedef enum : NSUInteger {
    kVIDEO_TYPE_AVFOUNDATION,
    kVIDEO_TYPE_QUICKTIME,
    kVIDEO_TYPE_NONE
} VideoControllerType;

typedef void (^PCVideoLoadingCompletedCallback)(void);
typedef void (^PCDirectAudioLoadingCompletedCallback)(void);

@protocol PCVideoControllerDelegate <NSObject>
@optional
- (BOOL)shouldLoadURL:(NSURL*)fileURL;
- (void)audioProxyFileWasCreated:(NSString*)proxyAVFilePath;
- (void)audioURLWasAddedToAVFoundationMovie:(NSURL*)url;
- (void)didLoadMovie:(PCVideoController*)vController;
@end

@interface PCVideoController : NSObject <PCDragViewControllerDelegate, PCTransportDelegateProcotol>{
    
    NSView * containerView;
    id <PCVideoControllerDelegate> delegate;
    NSString * contextString;
    BOOL fileIsCurrentlyLoaded;
    BOOL readyToLoadFile;
    
    PCAVMovieController * avMovieController;
    PCIOMovieController * ioMovieController;
    id <PCMovieControllerProxy> currentController;
    VideoControllerType currentVideoType;
    
    CALayer * currentLayerDisplayed;
    NSString * identifier;
    
    id <PCVideoTapDelegateProtocol> videoTapDelegate;
    BOOL showTime;
    
    PCVideoLoadingCompletedCallback loadCompletedCallback;
    PCTimeDisplayController * timeDisplayController;
}

+ (instancetype)videoController;
+ (instancetype)videoControllerQuicktimeDefered;

- (void)loadURL:(NSURL*)fileURL withContext:(NSString*)contextString;

//these do the same thing
- (void)clearMovieWindow;
- (void)clear;

//this is the layer that displays the video content,
//you can get the buffers outputted by the layer for additional purposes
- (id)videoTap;

//This is exposed so that you sync this against another AVPlayer
- (AVPlayer*)synchronizablePlayer;

//The forces the video output layer to emit the
//current pixel buffer again regardless of its time
- (void)shouldForceUpdate:(BOOL)val;

- (NSSize)movieSize;

- (BOOL)hasQuicktimeHelperLaunched;
- (BOOL)isPlaying;

- (void)directlyLoadIntoAudioURLIntoCurrentAVAsset:(NSURL*)fileURL withCallback:(PCDirectAudioLoadingCompletedCallback)audioCompletedCallback;

@property (nonatomic, assign, readwrite) NSView * containerView;
@property (nonatomic, assign, readwrite) id <PCVideoControllerDelegate> delegate;
@property (nonatomic, retain, readwrite) NSString * contextString;
@property (nonatomic, assign, readwrite) BOOL fileIsCurrentlyLoaded;
@property (nonatomic, assign, readwrite) BOOL readyToLoadFile;

@property (nonatomic, retain, readwrite) PCAVMovieController * avMovieController;
@property (nonatomic, retain, readwrite) PCIOMovieController * ioMovieController;
@property (nonatomic, assign, readwrite) id <PCMovieControllerProxy> currentController;
@property (nonatomic, assign, readwrite) VideoControllerType currentVideoType;

@property (nonatomic, assign, readwrite) CALayer * currentLayerDisplayed;
@property (nonatomic, retain, readwrite) NSString * identifier;

@property (nonatomic, assign, readwrite) id <PCVideoTapDelegateProtocol> videoTapDelegate;
@property (nonatomic, assign, readwrite) BOOL showTime;

@property (nonatomic, copy, readwrite) PCVideoLoadingCompletedCallback loadCompletedCallback;
@property (nonatomic, retain, readwrite) PCTimeDisplayController * timeDisplayController;

@end

@interface PCVideoController (information)
- (NSString*)codecForURL:(NSURL*)url;
- (BOOL)isURLAVFoundationPlayable:(NSURL*)url;
- (BOOL)URLIsQuicktimeCompatible:(NSURL*)url;
- (BOOL)URLcontainsVideoTracks:(NSURL*)url;
- (BOOL)URLcontainsAudioTracks:(NSURL*)url;
@end
