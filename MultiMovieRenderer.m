//
//  MultiMovieRenderer.m
//  IOSurfaceTest2
//
//  Created by Patrick Cusack on 5/7/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "MultiMovieRenderer.h"
#import "PCMovieRenderObject.h"

CVReturn myMMCVDisplayCallBack (CVDisplayLinkRef displayLink,
                              const CVTimeStamp *inNow,
                              const CVTimeStamp *inOutputTime,
                              CVOptionFlags flagsIn,
                              CVOptionFlags *flagsOut,
                              void *displayLinkContext){
    
    [(MultiMovieRenderer*)displayLinkContext getFrameDisplayLink:(double)inNow->videoTime];

    return kCVReturnSuccess;
}


@implementation MultiMovieRenderer
@synthesize doUUID;
@synthesize standardOut;
@synthesize movieA;

#pragma mark -
#pragma mark Application Life Cycle Calls
#pragma mark -

- (void)applicationDidFinishLaunching:(NSNotification *)notification{
    
    _parentID = getppid();
    
    // unique server name per plugin instance
    _theConnection = [[NSConnection new] retain];
    
    [_theConnection setRootObject:self];
    
    if ([_theConnection registerName:[NSString stringWithFormat:@"info.proxyplayer.movierenderer-%@", [self doUUID], nil]] == NO){
        NSLog(@"Error opening NSConnection - exiting");
    } else {
        NSLog(@"NSConnection Open");
    }
    
    // poll for parent app.
    [self setupPollParentTimer];
}


- (void)setupPollParentTimer{
    _pollParentTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) 1
                                                        target:self
                                                      selector:@selector(pollParent)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)pollParent{
    NSLog(@"Checking Parent: %@", [NSRunningApplication runningApplicationWithProcessIdentifier:_parentID]);
    if([NSRunningApplication runningApplicationWithProcessIdentifier:_parentID] == nil){
        [self quitHelperTool];
    }
}

-(oneway void)quitHelperTool{
    [self closeMovie];
    [[NSApplication sharedApplication] terminate:nil];
}

#pragma mark -


- (void)getFrameDisplayLink:(double)nTime{
    
    IOSurfaceID surfaceIDA = [[self movieA] hasNewFrameAtTime:nTime];
    
    if (surfaceIDA != UINT32_MAX) {
        char cmdStr[256];
        sprintf(cmdStr, "ID#%lu#\n", (unsigned long)[[self movieA] currentSurfaceID]);
        [standardOut writeData: [NSData dataWithBytesNoCopy: cmdStr length: strlen(cmdStr) freeWhenDone: NO]];
    }
}

- (void)setUpDisplayLink{
    mainDisplayID = kCGDirectMainDisplay;
    
    CVReturn error = CVDisplayLinkCreateWithCGDisplay(kCGDirectMainDisplay, &displayLink);
    
    if(error) {
        NSLog(@"DisplayLink created with error:%d", error);
        displayLink = NULL;
        return;
    }
    
    CVDisplayLinkSetCurrentCGDisplay(displayLink, kCGDirectMainDisplay);
    CVDisplayLinkSetOutputCallback(displayLink, myMMCVDisplayCallBack, self);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowChangedScreen:)
                                                 name:NSWindowDidChangeScreenNotification
                                               object:nil];
}

- (void)tearDownDisplayLink{
    if (displayLink) {
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
        displayLink = NULL;
    }
}

- (void)startDisplayLink{
    if(displayLink ){
        CVDisplayLinkStart(displayLink);
    }
}

- (void)stopDisplayLink{
    if(displayLink ){
        CVDisplayLinkStop(displayLink);
    }
}

#pragma mark -

- (id)init{
    if ([super init]) {
        timing = 0.0;
        [self setStandardOut:[(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] retain]];
        [self setUpDisplayLink];
    }
    return self;
}

- (oneway void)addAudioFileToCurrentMovie:(NSURL*)audioURL{
    if ([self movieA]) {
        [[self movieA] addAudioFileToCurrentMovie:audioURL];
    }
}

- (oneway void)addMovieURL:(NSURL*)movieURL{
    [self closeMovie];
    [self openMovieURL:movieURL];
}

- (oneway void)openMovieURL:(NSURL*)movieURL{

    PCMovieRenderObject * mov = [[[PCMovieRenderObject alloc] init] autorelease];
    [mov loadMovieURL:movieURL];
    [self setMovieA:mov];
    
    [self startDisplayLink];
}

- (NSString*)proxyMoviePath{
    if ([self movieA]) {
        if ([[self movieA] proxyMoviePath]) {
            return [[self movieA] proxyMoviePath];
        } else{
            return [[self movieA] moviePath];
        }
    }
    return nil;
}

- (void)closeMovie{
    [self setMovieA:nil];
    [self stopDisplayLink];
}

- (void)dealloc{
    
    if (_pollParentTimer) {
        [_pollParentTimer invalidate];
        _pollParentTimer = nil;
    }
    
    [self setDoUUID:nil];
    [self tearDownDisplayLink];
    [self setStandardOut:nil];
    [super dealloc];
}

- (void)play{
    if ([self movieA]) {
        [[self movieA] setMovieRate:1.0];
    }
}

- (void)pause{
    if ([self movieA]) {
        [[self movieA] setMovieRate:0.0];
    }
}

- (oneway void) setMovieIsPlaying:(BOOL)flag{
    if ([self movieA]) {
        [[self movieA] setMovieIsPlaying:flag];
    }
}

- (BOOL)hasMovie{
    if ([self movieA]) {
        return YES;
    }
    return NO;
}

-(BOOL)audioHasLoaded{
    if ([self movieA]) {
        return [[self movieA] audioHasLoaded];
    }
    return NO;
}

-(void)goToBeginning{
    if ([self movieA]) {
        [[self movieA] goToBeginning];
    }
}

- (void)goToEnd{
    if ([self movieA]) {
        [[self movieA] goToEnd];
    }
}

- (oneway void)goToTimeValue:(long)timeValue{
    if ([self movieA]) {
        [[self movieA] goToTimeValue:timeValue];
    }
}

- (oneway void)setMovieRate:(float)nRate{
    if ([self movieA]) {
        [[self movieA] setMovieRate:nRate];
    }
}

- (float)movieRate{
    if ([self movieA]) {
        return [[self movieA] movieRate];
    }
    return 0.0;
}

- (void)stepForward{
    if ([self movieA]) {
        [[self movieA] stepForward];
    }
}

- (void)stepBackward{
    if ([self movieA]) {
        [[self movieA] stepBackward];
    }
}

- (NSValue*)movieSize{
    if ([self movieA]) {
        return [[self movieA] movieSize];
    }
    return [NSValue valueWithSize:NSZeroSize];
}

- (long long)currentTimeValue{
    if ([self movieA]) {
        return [[self movieA] currentTimeValue];
    }
    return 0;
}

- (long long)maxTimeValue{
    if ([self movieA]) {
        return [[self movieA] maxTimeValue];
    }
    return 0;
}

- (long)timeScale{
    if ([self movieA]) {
        return [[self movieA] timeScale];
    }
    return 0;
}

- (BOOL)isMoviePlaying{
    if ([self movieA]) {
        return [[self movieA] isMoviePlaying];
    }
    return 0;
}

- (NSString *)moviePath{
    if ([self movieA]) {
        return [[self movieA] moviePath];
    }
    return @"";
}

- (NSTimeInterval)movieDuration{
    if ([self movieA]) {
        return [[self movieA] movieDuration];
    }
    return 0;
}

- (SInt32)nextInterestingDuration{
    if ([self movieA]) {
        return [[self movieA] nextInterestingDuration];
    }
    return 0;
}

- (NSTimeInterval)frameStep{
    if ([self movieA]) {
        return [[self movieA] frameStep];
    }
    return 0;
}

- (float)movieFrameRate{
    if ([self movieA]) {
        return [[self movieA] frameStep];
    }
    return 0;
}

- (float)nominalFrameRate{
    if ([self movieA]) {
        return [[self movieA] nominalFrameRate];
    }
    return 0;
}

- (NSTimeInterval)queuedMovieTime{
    if ([self movieA]) {
        return [[self movieA] queuedMovieTime];
    }
    return 0;
}

- (NSTimeInterval)movieTime{
    if ([self movieA]) {
        return [[self movieA] movieTime];
    }
    return 0;
}

- (void)setMovieTime: (NSTimeInterval)aDouble{
    if ([self movieA]) {
        [[self movieA] setMovieTime:aDouble];
    }
}


@end
