//
//  PCVideoController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 5/10/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCVideoController.h"
#import "PCAVMovieController.h"
#import "PCIOMovieController.h"
#import "PCVideoTransport.h"
#import "PCVideoStrings.h"
#import "ADRToolBoxLogger.h"


@interface PCVideoController(){
    CATextLayer * _info;
    int reloadAttemptCount;
}

- (void)addLayerToContainerView:(CALayer*)nLayer;

@property (nonatomic, assign, readwrite) int reloadAttemptCount;

@end

@implementation PCVideoController
@synthesize containerView;
@synthesize delegate;
@synthesize contextString;
@synthesize fileIsCurrentlyLoaded;
@synthesize readyToLoadFile;
@synthesize avMovieController;
@synthesize ioMovieController;
@synthesize currentController;
@synthesize currentVideoType;
@synthesize currentLayerDisplayed;
@synthesize identifier;
@synthesize videoTapDelegate;
@synthesize showTime;
@synthesize loadCompletedCallback;
@synthesize reloadAttemptCount;
@synthesize timeDisplayController;

#pragma mark -
#pragma mark class methods
#pragma mark -

+ (instancetype)videoController{
    return [[[PCVideoController alloc] init] autorelease];
}

+ (instancetype)videoControllerQuicktimeDefered{
    return [[[PCVideoController alloc] initWithDeferedQuicktimeLoader:YES] autorelease];
}

#pragma mark -
#pragma mark instance methods
#pragma mark -

- (instancetype)init{
    return [self initWithDeferedQuicktimeLoader:NO];
}

- (instancetype)initWithDeferedQuicktimeLoader:(BOOL)defer{
    self = [super init];
    if (self) {
        [self setCurrentController:nil];
        [self setCurrentVideoType:kVIDEO_TYPE_NONE];
        [self setReadyToLoadFile:NO];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resize:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:nil];
        
        PCAVMovieController * avController = [[[PCAVMovieController alloc] init] autorelease];
        [self setAvMovieController:avController];
        
        if (defer == YES) {
            [self setIoMovieController:nil];
        } else {
            PCIOMovieController * ioController = [[[PCIOMovieController alloc] init] autorelease];
            [self setIoMovieController:ioController];
            
            [ADRToolBoxLogger addString:@"Will launch the helper tool."];
            [[self ioMovieController] launchHelperAsyncWithCallback:^(BOOL ready) {
                if (ready) {
                    [ADRToolBoxLogger addString:@"Successfully loaded the asynchronous helper."];
                } else {
                    [ADRToolBoxLogger addString:@"There was an error loading the [launchHelperAsyncWithCallback]."];
                }
            }];
        }
    
        
        [self setIdentifier:@"Z"];
        [[self avMovieController] setIdentifier:@"Z"];
        [[self ioMovieController] setIdentifier:@"Z"];
        
        [self setVideoTapDelegate:nil];
        [self setShowTime:YES];
        
        [self setReloadAttemptCount:0];
    }
    return self;
}

- (void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self avMovieController] disengageController]; //This pauses and stops the time updates
    [[self ioMovieController] disengageController];
    
    [[self currentLayerDisplayed] removeFromSuperlayer];
    [self setCurrentLayerDisplayed:nil];
    [self setContainerView:nil];

    [self setDelegate:nil];
    [self setContextString:nil];
    [self setFileIsCurrentlyLoaded:NO];
    [self setCurrentVideoType:kVIDEO_TYPE_NONE];

    [self setAvMovieController:nil];
    [self setIoMovieController:nil];
    [self setCurrentController:nil];
    [self setIdentifier:nil];
    [self setVideoTapDelegate:nil];
    
    [self setLoadCompletedCallback:nil];
    [self setTimeDisplayController:nil];
    
    [super dealloc];
}

- (void)setIdentifier:(NSString *)nIdentifier{
    
    [nIdentifier retain];
    [identifier release];
    identifier = nIdentifier;
    
    [[self avMovieController] setIdentifier:nIdentifier];
    [[self ioMovieController] setIdentifier:nIdentifier];
}

- (void)setVideoTapDelegate:(id<PCVideoTapDelegateProtocol>)nVideoTapDelegate{
    videoTapDelegate = nVideoTapDelegate;
    if ([self avMovieController]) {
        [[self avMovieController] setVideoTapDelegate:nVideoTapDelegate];
    }
}

- (void)clearMovieWindow{
    [self clear];
}

- (void)clear{
    
    if ([self currentVideoType] == kVIDEO_TYPE_AVFOUNDATION) {
        [[self avMovieController] disengageController];
    } else if ([self currentVideoType] == kVIDEO_TYPE_QUICKTIME){
        [[self ioMovieController] disengageController];
    }
    
    [[self currentLayerDisplayed] removeFromSuperlayer];
    [self setCurrentLayerDisplayed:nil];
    
    [self setCurrentVideoType:kVIDEO_TYPE_NONE];
    [self setFileIsCurrentlyLoaded:NO];
}

- (void)loadURL:(NSURL*)fileURL withContext:(NSString *)nContextString{
    
    [ADRToolBoxLogger addString:[NSString stringWithFormat:@"Will load %@", fileURL]];
    
    BOOL isPlayerCurrentlyPlaying = [[self currentController] isPlayerPlaying];
    
    //ask delegate if we should load
    if([self delegate] && [[self delegate] respondsToSelector:@selector(shouldLoadURL:)]){
        if ([[self delegate] shouldLoadURL:fileURL] == NO) {
            return;
        }
    }
    
    //if they are dropping audio on a video player wiithout video, then skip
    if (![self URLcontainsVideoTracks:fileURL] && [self fileIsCurrentlyLoaded] == NO) {
        return;
    } else if([self URLcontainsAudioTracks:fileURL] && ![self URLcontainsVideoTracks:fileURL] && [self fileIsCurrentlyLoaded] == YES){
        //then add audio to video asset
        //notify user that adding audio file to an asset that already has one will temporarily replace the existing audio
        
        if ([self currentVideoType] == kVIDEO_TYPE_AVFOUNDATION) {
            //This should be added audio and go to time in avMovieController class
            __block PCAVMovieController * weakSelf = [self avMovieController];
            [weakSelf saveCurrentTime];
            [[self avMovieController] addAudioURLToCurrentVideoAsset:fileURL withCallBack:^(BOOL ready) {
                if (ready) {
                    [weakSelf restoreCurrentTime];
                    
                    if([self delegate] && [[self delegate] respondsToSelector:@selector(audioURLWasAddedToAVFoundationMovie:)]){
                        [[self delegate] audioURLWasAddedToAVFoundationMovie:fileURL];
                    }
                    
                } else {
                    NSLog(@"Unable to 'kVIDEO_TYPE_AVFOUNDATION: addAudioURLToCurrentVideoAsset' in PCVideoController");
                }
            }];
            
        } else if ([self currentVideoType] == kVIDEO_TYPE_QUICKTIME){
            
            __block PCIOMovieController * weakController = [self ioMovieController];
            [weakController saveCurrentTime];
            
            [[self ioMovieController] addAudioURLToCurrentVideoAsset:fileURL withCallBack:^(BOOL ready) {
                if (ready) {
                    [weakController restoreCurrentTime];
                    
                    if([self delegate] && [[self delegate] respondsToSelector:@selector(audioProxyFileWasCreated:)]){
                        [[self delegate] audioProxyFileWasCreated:[weakController proxyMoviePath]];
                    }
                    
                } else {
                    NSLog(@"Unable to 'kVIDEO_TYPE_QUICKTIME: addAudioURLToCurrentVideoAsset' in PCVideoController");
                }
            }];
        }

        return;
    }
    
    if ([self isURLAVFoundationPlayable:fileURL]) {
        
        if ([self currentVideoType] != kVIDEO_TYPE_AVFOUNDATION) {
            [self clear];
            
            [self addLayerToContainerView:[[self avMovieController] layerToDisplay]];
            [self setCurrentVideoType:kVIDEO_TYPE_AVFOUNDATION];
            [self setCurrentController:[self avMovieController]];
        }
        
        __block PCAVMovieController * weakPlayer = [self avMovieController];
        __block PCVideoController * weakController = self;
        
        [self showLoadingLayerOnLayer:[self currentLayerDisplayed]];
        
        [[self avMovieController] loadURL:fileURL withCallBack:^(BOOL ready) {
            if (ready) {
                
                //This is a hacky way to get the frame counter to show the beginning of the movie
                [weakPlayer goToFrame:@1];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakPlayer goToFrame:@0];
                    [weakController setFileIsCurrentlyLoaded:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:KENABLETRANSPORTCONTROL
                                                                        object:@{@"object":weakController, @"identifier":[weakController identifier]}];
                    
                    if ([weakController delegate] && [[weakController delegate] respondsToSelector:@selector(didLoadMovie:)]) {
                        [[weakController delegate] didLoadMovie:weakController];
                    }
                    
                    [weakController removeLoadingLayer];
                    
                    if ([weakController loadCompletedCallback]) {
                        loadCompletedCallback();
                        [weakController setLoadCompletedCallback:nil];
                        if (isPlayerCurrentlyPlaying == YES) {
                            [self play];
                        }
                    }

                });
                
            }
        }];
    
    } else if ([self URLIsQuicktimeCompatible:fileURL] == YES){

        //did we defer loading
        if (![self ioMovieController]) {
            PCIOMovieController * ioController = [[[PCIOMovieController alloc] init] autorelease];
            [self setIoMovieController:ioController];
            
            [ADRToolBoxLogger addString:@"Performing deferred launch the helper tool."];
            [[self ioMovieController] launchHelperAsyncWithCallback:^(BOOL ready) {
                if (ready) {
                    [ADRToolBoxLogger addString:@"Successfully loaded the asynchronous helper."];
                } else {
                    [ADRToolBoxLogger addString:@"There was an error loading the [launchHelperAsyncWithCallback]."];
                }
            }];
            
            [self showLoadingLayerOnLayer:[[self containerView] layer]];
            if ([self shouldReloadWithURL:fileURL andContext:nContextString] == YES) {
                return;
            }
        }
        
        if ([self currentVideoType] != kVIDEO_TYPE_QUICKTIME) {
            [self clear];
            
            [self addLayerToContainerView:[[self ioMovieController] layerToDisplay]];
            [self setCurrentVideoType:kVIDEO_TYPE_QUICKTIME];
            [self setCurrentController:[self ioMovieController]];
        }
    
        [self showLoadingLayerOnLayer:[self currentLayerDisplayed]];
        
        //we would experience this if we instantiated the player and immediately loaded a movie
        //before the quicktime player started
        if ([self shouldReloadWithURL:fileURL andContext:nContextString] == YES) {
            return;
        }
    
        __block PCVideoController * weakController = self;
        
        [ADRToolBoxLogger addString:@"About to load Quicktime Movie"];
        
        [[self ioMovieController] loadURL:fileURL withCallBack:^(BOOL ready) {
            if (ready) {
                [weakController setFileIsCurrentlyLoaded:YES];
                [[NSNotificationCenter defaultCenter] postNotificationName:KENABLETRANSPORTCONTROL
                                                                    object:@{@"object":weakController, @"identifier":[weakController identifier]}];
     
                if ([weakController delegate] && [[weakController delegate] respondsToSelector:@selector(didLoadMovie:)]) {
                    [[weakController delegate] didLoadMovie:weakController];
                }
                
                [ADRToolBoxLogger addString:@"Loaded Quicktime movie."];
                
                [self removeLoadingLayer];
                
                if ([weakController loadCompletedCallback]) {
                    [ADRToolBoxLogger addString:@"Running load completed callback."];
                    loadCompletedCallback();
                    [weakController setLoadCompletedCallback:nil];
                    if (isPlayerCurrentlyPlaying == YES) {
                        [self play];
                    }
                }
            }
        }];
    }

}


//When starting the application, a movie could load and the helper tool might not have already loaded
//this is a callback than be recussively invoked until the helper tools loads or the increment count exceeds a limit.
- (BOOL)shouldReloadWithURL:(NSURL*)url andContext:(NSString*)nContextString{
    
    if ([self hasExceededReloadAttempts] == YES) {
        [self showReloadAttempExceededError];
        return NO;
    }
    
    if ([self hasQuicktimeHelperLaunched] == NO) {
        
        [ADRToolBoxLogger addString:@"PCVideoController: attempting reload..."];
        
        [self incrementReloadAttemptCount];
        
        __block PCVideoController * weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf loadURL:url withContext:nContextString];
        });
        
        return YES;
    }
    
    [ADRToolBoxLogger addString:@"PCVideoController: does not need to reload..."];
    [self resetReloadAttemptCount];
    return NO;
}

- (void)addLayerToContainerView:(CALayer*)nLayer{
    NSRect bounds = [[self containerView] bounds];
    [nLayer setBounds:NSRectToCGRect(bounds)];
    [nLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [nLayer setNeedsDisplay];
    [[[self containerView] layer] addSublayer:nLayer];
    [[[self containerView] layer] setNeedsDisplay];
    [self setCurrentLayerDisplayed:nLayer];
}

- (void)setContainerView:(NSView *)nContainerView{
    containerView = nil;
    [nContainerView setWantsLayer:YES];
    containerView = nContainerView;
    [containerView setPostsBoundsChangedNotifications:YES];
}

- (void)resize:(NSNotification*)aNotif{
    
    if ([aNotif object] != [self containerView]) {
        return;
    }
    
    NSRect bounds = [[self containerView] bounds];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    if ([self currentVideoType] == kVIDEO_TYPE_AVFOUNDATION) {
        [(PCAVMovieController*)[self currentController] resize];
    }
    
    [[self currentLayerDisplayed] setBounds:NSRectToCGRect(bounds)];
    [[self currentLayerDisplayed] setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [[self currentLayerDisplayed] setNeedsDisplay];
    [CATransaction commit];
}

- (id)videoTap{
    if ([self avMovieController]) {
        return (id)[[self avMovieController] videoOutputLayer];
    }
    return nil;
}

- (AVPlayer*)synchronizablePlayer{
    if ([self avMovieController]) {
        return [(id)[[self avMovieController] moviePlayer] player];
    }
    return nil;
}

- (NSSize)movieSize{
    return [[self currentController] movieSize];
}

- (BOOL)hasQuicktimeHelperLaunched{
    
    if (![self ioMovieController]) {return NO;}
    return [[[self ioMovieController] moviePlayer] helperIsReady];
}

- (BOOL)isPlaying{
    return [[self currentController] isPlayerPlaying];
}

- (void)shouldForceUpdate:(BOOL)val{
    if ([self avMovieController]) {
        return [[self avMovieController] shouldForceUpdate:YES];
    }
}

- (void)setShowTime:(BOOL)nShowTime{
    
    showTime = nShowTime;
    if ([self avMovieController]) {
        [[self avMovieController] setShowTime:nShowTime];
    }
    
    if ([self ioMovieController]) {
        [[self ioMovieController] setShowTime:nShowTime];
    }
}

- (void)showLoadingLayerOnLayer:(CALayer*)hostLayer{
    [self removeLoadingLayer];
    
    CATextLayer * loadingLayer = [self constructTextLayerOnLayer:hostLayer];
    [loadingLayer setString:@"Loading"];
    [self sizeTextLayer:loadingLayer forString:@"Loading"];
    [hostLayer addSublayer:loadingLayer];
    _info = loadingLayer;
}

- (void)removeLoadingLayer{
    if (_info) {
        [_info removeFromSuperlayer];
        _info = nil;
    }
}

- (CATextLayer*)constructTextLayerOnLayer:(CALayer*)hostLayer{
    
    CGColorRef clearColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.0);
    CGColorRef whiteColor = CGColorCreateGenericRGB(1.0, 1.0, 1.0, 1.0);
    CGColorRef shadowColor = CGColorCreateGenericRGB(0.0, 0.0, 0.0,1.0);
    CGColorRef redColor = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    CGColorRef blueColor = CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
    
    CGRect bounds = [hostLayer bounds];
    
    CATextLayer * nTextLayer = [CATextLayer layer];
    [nTextLayer setBackgroundColor:clearColor];
    [nTextLayer setForegroundColor:whiteColor];
    [nTextLayer setShadowColor:shadowColor];
    
    [nTextLayer setShadowOffset:CGSizeMake(0, -2)];
    [nTextLayer setShadowOpacity:1.0];
    [nTextLayer setPosition:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    [nTextLayer setBounds:CGRectMake(0, 0, bounds.size.width, 52)];
    
    [nTextLayer setContentsGravity:kCAGravityCenter];
    [nTextLayer setAutoresizingMask: kCALayerWidthSizable];
    [nTextLayer setAlignmentMode:kCAAlignmentCenter];
    [nTextLayer setContentsScale:2.0];
    [nTextLayer setFontSize:40.0];
    [nTextLayer setMasksToBounds:NO];
    
    CFRelease(clearColor);
    CFRelease(whiteColor);
    CFRelease(shadowColor);
    CFRelease(redColor);
    CFRelease(blueColor);
    
    return nTextLayer;
}

- (void)sizeTextLayer:(CATextLayer*)nLayer forString:(NSString*)nString{
    
    float maxWidth = 0.5;
    
    NSSize size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:[nLayer fontSize]]}];
    CGFloat currentFontSize = [nLayer fontSize];
    
    if (size.width < ([nLayer bounds].size.width * maxWidth)) {
        while (size.width < ([nLayer bounds].size.width * maxWidth)) {
            currentFontSize += 1.0;
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [nLayer setBounds:CGRectMake(0, 0, [nLayer bounds].size.width, currentFontSize + (currentFontSize/5.0))];
            [CATransaction commit];
        }
        
        return;
    }
    
    if (size.width > [nLayer bounds].size.width * maxWidth) {
        while (size.width > [nLayer bounds].size.width * maxWidth) {
            currentFontSize -= 1.0;
            size = [nString sizeWithAttributes:@{NSFontAttributeName:[NSFont fontWithName:@"Helvetica" size:currentFontSize]}];
            [CATransaction begin];
            [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
            [nLayer setFontSize:currentFontSize];
            [nLayer setBounds:CGRectMake(0, 0, [nLayer bounds].size.width, currentFontSize + (currentFontSize/5.0))];
            [CATransaction commit];
        }
        
        return;
    }
    
}

- (void)directlyLoadIntoAudioURLIntoCurrentAVAsset:(NSURL*)fileURL withCallback:(PCDirectAudioLoadingCompletedCallback)audioCompletedCallback{
    
    __block PCAVMovieController * weakSelf = [self avMovieController];
    [weakSelf saveCurrentTime];
    
    [[self avMovieController] addAudioURLToCurrentVideoAsset:fileURL withCallBack:^(BOOL ready) {
        if (ready) {
            if (audioCompletedCallback) {
                audioCompletedCallback();
            }
        } else {
            NSLog(@"Unable to 'kVIDEO_TYPE_AVFOUNDATION: addAudioURLToCurrentVideoAsset' in PCVideoController");
        }
    }];
}

- (void)setTimeDisplayController:(PCTimeDisplayController *)nTimeDisplayController{
    [nTimeDisplayController retain];
    [timeDisplayController release];
    timeDisplayController = nTimeDisplayController;
    
    [[self avMovieController] setTimeDisplayController:nTimeDisplayController];
    [[self ioMovieController] setTimeDisplayController:nTimeDisplayController];
    
    [self shouldForceUpdate:YES];
}

#pragma mark -
#pragma mark Quicktime Helper Tool Reload
#pragma mark -

- (BOOL)hasExceededReloadAttempts{
    if ([self reloadAttemptCount] > 6) {
        return YES;
    }
    return NO;
}

- (void)incrementReloadAttemptCount{
    [self setReloadAttemptCount:[self reloadAttemptCount]+1];
}

- (void)resetReloadAttemptCount{
    [self setReloadAttemptCount:0];
}

- (void)showReloadAttempExceededError{
    NSAlert * alertPanel = [[NSAlert alloc] init];
    [alertPanel setMessageText:@"Error"];
    [alertPanel setInformativeText:@"Unable to launch Quicktime Helper Process after too many attempts."];
    [alertPanel addButtonWithTitle:@"OK"];
    (void)[alertPanel runModal];
    [alertPanel release];
}

#pragma mark -
#pragma mark PCDragViewControllerDelegate
#pragma mark -

- (void)handleDragURL:(NSURL *)dragURL{
    [self loadURL:dragURL withContext:@"DragContext"];
}

- (BOOL)canViewGoToFrame{
    return [self fileIsCurrentlyLoaded];
}

- (void)dragViewWantsToGoToFrame:(NSNumber*)frame{
    [self goToFrame:frame];
}

- (void)dragViewWantsToGoToPercentage:(float)percentage{
    if ([self currentController]) {
        [[self currentController] goToPercentage:percentage];
    }
}

- (CALayer*)controllerVideoLayer{
    return [self currentLayerDisplayed];
}

#pragma mark -
#pragma mark PCTransportDelegateProcotol
#pragma mark -

- (void)play{
    if ([self currentController]) {
        [[self currentController] play];
    }
}

- (void)pause{
    if ([self currentController]) {
        [[self currentController] pause];
    }
}

- (void)togglePlay{
    
}

- (void)stepForward{
    if ([self currentController]) {
        [[self currentController] stepForward];
    }
}

- (void)stepBackward{
    if ([self currentController]) {
        [[self currentController] stepBackward];
    }
}

- (void)goToPosition:(float)percentage{
    if ([self currentController]) {
        [[self currentController] goToPercentage:percentage];
    }
}

- (void)goToBeginning{
    if ([self currentController]) {
        [[self currentController] goToBeginning];
    }
}

- (void)goToEnd{
    if ([self currentController]) {
        [[self currentController] goToEnd];
    }
}

- (void)goToFrame:(NSNumber*)frame{
    if ([self currentController]) {
        [[self currentController] goToFrame:frame];
    }
}

- (void)goToTime:(NSNumber*)time withPictureStart:(NSNumber*)pictureStart{
    if ([self currentController]) {
        [[self currentController] goToTime:time withPictureStart:pictureStart];
    }
}

- (NSUInteger)currentFrame{
    if ([self currentController]) {
        return [[self currentController] currentFrame];
    }
    return 0;
}

@end


@implementation PCVideoController (information)

- (NSString*)codecForURL:(NSURL*)url{
    AVAsset * asset = [AVAsset assetWithURL:url];
    if(asset){
        NSArray * videoTracks = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
        if([videoTracks count] > 0){
            NSArray * formatDescriptions = [[videoTracks objectAtIndex:0] formatDescriptions];
            for (id fDescr in formatDescriptions) {
                return NSFileTypeForHFSTypeCode(CMFormatDescriptionGetMediaSubType((CMFormatDescriptionRef)fDescr));
            }
        }
    }
    return nil;
}

- (BOOL)isURLAVFoundationPlayable:(NSURL*)url{
    AVAsset * asset = [AVAsset assetWithURL:url];
    if(asset && [asset isPlayable]){
        return YES;
    }
    return NO;
}

- (BOOL)URLIsQuicktimeCompatible:(NSURL*)url{
    NSString * videoCodecForURL = [self codecForURL:url];
    NSArray * altCodecs = @[@"'AVdn'"];
    if ([altCodecs containsObject:videoCodecForURL]) {
        return YES;
    }
    return NO;
}

- (BOOL)URLcontainsVideoTracks:(NSURL*)url{
    AVAsset * asset = [AVAsset assetWithURL:url];
    if(asset){
        NSArray * videoTracks = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
        if([videoTracks count] > 0){
            return YES;
        }
    }
    return NO;
}

- (BOOL)URLcontainsAudioTracks:(NSURL*)url{
    AVAsset * asset = [AVAsset assetWithURL:url];
    if(asset){
        NSArray * audioTracks = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicAudible];
        if([audioTracks count] > 0){
            return YES;
        }
    }
    return NO;
}


@end
