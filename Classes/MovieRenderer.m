/*
 *  MovieRenderer.m
 *  IOSurfaceCLI
 *
 *  Created by Paolo on 21/09/2009.
 *
 * Copyright (c) 2009 Paolo Manna
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this list of
 *   conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, this list of
 *   conditions and the following disclaimer in the documentation and/or other materials
 *   provided with the distribution.
 * - Neither the name of the Author nor the names of its contributors may be used to
 *   endorse or promote products derived from this software without specific prior written
 *   permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "MovieRenderer.h"

@interface QTMovie (QTFrom763)
- (QTTime)frameStartTime: (QTTime)atTime;
- (QTTime)frameEndTime: (QTTime)atTime;
- (QTTime)keyframeStartTime:(QTTime)atTime;
@end

@interface MovieRenderer (FrameQueueHandling)
- (NSTimeInterval)refHostTime;
- (void)setRefHostTime: (NSTimeInterval)aTime;
- (void)addToFrameQueue: (CVImageBufferRef)currentFrame atTime: (NSTimeInterval)aTime;
@end

static void frameAvailable(QTVisualContextRef vContext, const CVTimeStamp *frameTime, void *refCon)
{
    MovieRenderer		*renderer	= (MovieRenderer *)refCon;
    CVImageBufferRef	currentFrame;
    NSTimeInterval		realTime	= 0.0;
    OSStatus			err;
    NSAutoreleasePool	*pool		= [[NSAutoreleasePool alloc] init];
    
    if (frameTime->flags & kCVTimeStampVideoTimeValid)
        realTime = (NSTimeInterval)(frameTime->videoTime) / (NSTimeInterval)(frameTime->videoTimeScale);
    else if (frameTime->flags & kCVTimeStampHostTimeValid) {
        realTime = (double)AudioConvertHostTimeToNanos(frameTime->hostTime) / 1000000000.0;
        
        if ([renderer refHostTime] <= 0.0)
            [renderer setRefHostTime: realTime];
        
        realTime	-= [renderer refHostTime];
    }
    
    if ((err = QTVisualContextCopyImageForTime(vContext, NULL, frameTime, &currentFrame)) == kCVReturnSuccess) {
        [renderer addToFrameQueue: currentFrame atTime: realTime];
    } else {
        NSLog(@"Error %d getting frame at %.2f", (int)err, realTime);
    }
    
    [pool release];
}

CVReturn myCVDisplayCallBack (CVDisplayLinkRef displayLink,
                              const CVTimeStamp *inNow,
                              const CVTimeStamp *inOutputTime,
                              CVOptionFlags flagsIn,
                              CVOptionFlags *flagsOut,
                              void *displayLinkContext){
    
    [(MovieRenderer*)displayLinkContext getFrameDisplayLink:(double)inNow->videoTime];
    
    
    return kCVReturnSuccess;
}


@implementation MovieRenderer
@synthesize doUUID;
@synthesize standardOut;

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
    
    if([NSRunningApplication runningApplicationWithProcessIdentifier:_parentID] == nil){
        [self quitHelperTool];
    }
    
}

-(oneway void)quitHelperTool{
    [self closeMovie];
    [[NSApplication sharedApplication] terminate:nil];
}

#pragma mark -

- (void)getFrame:(NSTimer *)aTimer
{
    id newFrame	= [self getFrameAtTime: timing];
    
    if (newFrame) {
        if (newFrame != _currentFrame) {
            char		cmdStr[256];
            
#if COREVIDEO_SUPPORTS_IOSURFACE
            sprintf(cmdStr, "ID#%lu#\n", (unsigned long)[self currentSurfaceID]);
#else
            sprintf(cmdStr, "F#%lu#\n", (unsigned long)[self currentFrame]);
#endif
            [standardOut writeData: [NSData dataWithBytesNoCopy: cmdStr length: strlen(cmdStr) freeWhenDone: NO]];
            _currentFrame	= newFrame;
        }
        timing	+= [aTimer timeInterval];
    }
}

- (void)getFrameDisplayLink:(double)nTime
{
    id newFrame	= [self getFrameAtTime: nTime];
    
    if (newFrame) {
        if (newFrame != _currentFrame) {
            char		cmdStr[256];
            
#if COREVIDEO_SUPPORTS_IOSURFACE
            sprintf(cmdStr, "ID#%lu#\n", (unsigned long)[self currentSurfaceID]);
#else
            sprintf(cmdStr, "F#%lu#\n", (unsigned long)[self currentFrame]);
#endif
            [standardOut writeData: [NSData dataWithBytesNoCopy: cmdStr length: strlen(cmdStr) freeWhenDone: NO]];
            _currentFrame	= newFrame;
        }
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
    CVDisplayLinkSetOutputCallback(displayLink, myCVDisplayCallBack, self);
    
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
        [self setStandardOut:[(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] retain]];
        timing = 0.0;
        [self setUpDisplayLink];
    }
    return self;
}

- (oneway void)addMovieURL:(NSURL*)movieURL{
    [self closeMovie];
    [self openMovieURL:movieURL];
}

- (oneway void)openMovieURL:(NSURL*)movieURL{
    
    NSString * aPath = [movieURL path];
    
    NSDictionary	*ctxAttrs	= [NSDictionary dictionaryWithObjectsAndKeys: [self pixelBufferAttributes], kQTVisualContextPixelBufferAttributesKey,
                                   [NSNumber numberWithFloat: 0.0], kQTVisualContextExpectedReadAheadKey,
                                   nil];
    
    NSDictionary	* movieAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], QTMovieRateChangesPreservePitchAttribute,
                                    [NSNumber numberWithBool:NO], QTMovieOpenAsyncOKAttribute,
                                    aPath, QTMovieFileNameAttribute,
                                    nil];
    
    
    QTPixelBufferContextCreate(kCFAllocatorDefault, (CFDictionaryRef)ctxAttrs, &vContext);
    
    moviePath	= [aPath copy];
    
    NSError * e = nil;
    qtMovie = [[QTMovie alloc] initWithAttributes: movieAttrs error: &e];
    
    if (qtMovie) {
        NSUInteger	playHints	= hintsHighQuality;
        Movie		inMovie		= [qtMovie quickTimeMovie];
        TimeScale	tScale		= GetMovieTimeScale(inMovie);
        
        [qtMovie gotoBeginning];
        
        refHostTime	= -1.0;
        
        SetMovieVisualContext(inMovie, vContext);
        SetMoviePlayHints(inMovie, playHints, playHints);
        PrePrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie), NULL, NULL);
        PrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie));
        
        if ([qtMovie respondsToSelector: @selector(frameEndTime:)]) {
            // Only on QT 7.6.3
            QTTime	qtStep	= [qtMovie frameEndTime: QTMakeTime(0, tScale)];
            QTGetTimeInterval (qtStep, &frameStep);
        } else {
            [qtMovie stepForward];
            QTGetTimeInterval ([qtMovie currentTime], &frameStep);
            [qtMovie gotoBeginning];
        }
        
        QTVisualContextSetImageAvailableCallback(vContext, frameAvailable, self);
        
        //this primes the buffers to begin decoding
        [qtMovie setRate:0.1];
        [qtMovie setRate:0.0];
        [qtMovie gotoBeginning];
    }
    
    maxQueueSize	= 1;
    _movieLock		= OS_SPINLOCK_INIT;
    _isMoviePlaying = NO;
    
    [self startDisplayLink];
}

- (void)closeMovie{
    
    [self stopDisplayLink];
    [self stopAndReleaseMovie];
    
    if (vContext) {
        QTVisualContextRelease(vContext);
    }
    
    [moviePath release];
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
    [self setMovieIsPlaying:YES];
}

- (void)pause{
    [self setMovieIsPlaying:NO];
}

- (oneway void) setMovieIsPlaying:(BOOL)flag{
    
    if (![self hasMovie]) {
        return;
    }
    
    if (_isMoviePlaying == YES) {
        [qtMovie stop];
        _isMoviePlaying = NO;
    } else{
        [self setMovieRate: 1.0];
        _isMoviePlaying = YES;
    }
}

- (BOOL)hasMovie{
    if (qtMovie) {
        return YES;
    }
    return NO;
}

-(void)goToBeginning{
    if (![self hasMovie]) {
        return;
    }
    
    [qtMovie gotoBeginning];
}

- (void)goToEnd{
    if (![self hasMovie]) {
        return;
    }
    
    [qtMovie gotoEnd];
}

- (oneway void)goToTimeValue:(long)timeValue{
    if (![self hasMovie]) {
        return;
    }
    
    QTTime cTime = [qtMovie currentTime];
    QTTime nTime;
    nTime.timeValue = timeValue;
    nTime.timeScale = cTime.timeScale;
    nTime.flags = cTime.flags;
    
    [qtMovie setCurrentTime:nTime];
}

- (oneway void)setMovieRate:(float)nRate{
    if (![self hasMovie]) {
        return;
    }
    
    [qtMovie setRate:nRate];
}

- (float)movieRate
{
    if (qtMovie)
        return [qtMovie rate];
    else
        return 0.0;
}

- (void)forward{
    if (![self hasMovie]) {
        return;
    }
    
    [qtMovie stepForward];
}

- (void)back{
    if (![self hasMovie]) {
        return;
    }
    
    [qtMovie stepBackward];
}

- (NSValue*)movieSize{
    if (![self hasMovie]) {
        return nil;
    }
    
    return [[qtMovie movieAttributes] valueForKey:QTMovieNaturalSizeAttribute];
}

- (long long)currentTimeValue{
    if (![self hasMovie]) {
        return 0;
    }
    return [qtMovie currentTime].timeValue;
}

- (long long)maxTimeValue{
    if (![self hasMovie]) {
        return 0;
    }
    return [[qtMovie attributeForKey:QTMovieDurationAttribute] QTTimeValue].timeValue;
}

- (long)timeScale{
    if (![self hasMovie]) {
        return 0;
    }
    return [[qtMovie attributeForKey:QTMovieDurationAttribute] QTTimeValue].timeScale;
}

- (BOOL)isMoviePlaying{
    return _isMoviePlaying;
}

- (void)stopAndReleaseMovie
{
    if (qtMovie) {
        [qtMovie stop];
        QTVisualContextSetImageAvailableCallback(vContext, NULL, NULL);
        SetMovieVisualContext([qtMovie quickTimeMovie], NULL);
        [qtMovie release];
        qtMovie = nil;
    }
    
    [self releaseFrameQueue];
}

- (void)idle
{
    if (vContext)
        QTVisualContextTask(vContext);
}

- (NSString *)moviePath
{
    return moviePath;
}

- (NSTimeInterval)movieDuration
{
    if (qtMovie) {
        QTTime			qtDuration	= [qtMovie duration];
        return (double)qtDuration.timeValue / (double)qtDuration.timeScale;
    }
    
    return 0;
}

- (NSTimeInterval)frameStep
{
    return frameStep;
}

- (float)movieFrameRate
{
    if (frameStep > 0.0)
        return 1.0 / frameStep;
    
    return 0.0;
}

- (NSTimeInterval)queuedMovieTime
{
    return frameStep * maxQueueSize;
}

- (NSInteger)maxQueueSize
{
    return maxQueueSize;
}

- (void)setMaxQueueSize: (NSInteger)aSize
{
    if (aSize < 4)
        aSize	= 4;
    else if (aSize > FRAME_QUEUE_SIZE)
        aSize	= FRAME_QUEUE_SIZE;
    
    OSSpinLockLock(&_movieLock);
    
    if (aSize < maxQueueSize) {
        // Shift the queue, discarding oldest frames
        NSInteger	diff	= maxQueueSize - aSize;
        NSInteger	ii;
        
        for (ii = 0; ii < diff; ii++)
            CVBufferRelease(frameQueue[ii].frameBuffer);
        
        for (ii = 0; ii < aSize; ii++)
            frameQueue[ii]	= frameQueue[ii + diff];
        
        for (ii = aSize; ii < maxQueueSize; ii++) {
            frameQueue[ii].frameBuffer	= nil;
            frameQueue[ii].frameTime	= 0.0;
        }
    }
    
    maxQueueSize	= aSize;
    
    OSSpinLockUnlock(&_movieLock);
}


- (float)movieVolume
{
    if (qtMovie) {
        return [[qtMovie attributeForKey: QTMovieVolumeAttribute] floatValue];
    } else {
        return 0.0;
    }
}

- (void)setMovieVolume: (float)aFloat
{
    if (qtMovie)
        [qtMovie setAttribute: [NSNumber numberWithFloat: aFloat] forKey: QTMovieVolumeAttribute];
}

- (NSTimeInterval)movieTime
{
    if (qtMovie) {
        NSTimeInterval	currentTime;
        
        QTGetTimeInterval([qtMovie currentTime], &currentTime);
        
        return currentTime;
    } else {
        return 0.0;
    }
    
}

- (void)setMovieTime: (NSTimeInterval)aDouble
{
    if (qtMovie) {
        [qtMovie setCurrentTime: QTMakeTimeWithTimeInterval(aDouble)];
    }
}

- (NSDictionary *)pixelBufferAttributes
{
#if COREVIDEO_SUPPORTS_IOSURFACE
    NSDictionary		*ioAttrs	= [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                         forKey: (NSString *)kIOSurfaceIsGlobal];
    NSMutableDictionary	*pbAttrs	= [NSMutableDictionary dictionaryWithObject: ioAttrs
                                                                      forKey: (NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    NSLog(@"uses iosurfaces");
#else
    NSMutableDictionary	*pbAttrs	= [NSMutableDictionary dictionaryWithCapacity: 1];
#endif
    
//    if (gUseAlpha){
//        [pbAttrs setObject: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA]
//                    forKey: (NSString *)kCVPixelBufferPixelFormatTypeKey];
//        NSLog(@"Use alpha");
//    } else {
        [pbAttrs setObject: [NSNumber numberWithInt: kCVPixelFormatType_422YpCbCr8]
                    forKey: (NSString *)kCVPixelBufferPixelFormatTypeKey];
        NSLog(@"no use alpha");
//    }
    
    return pbAttrs;
}

#if COREVIDEO_SUPPORTS_IOSURFACE
- (IOSurfaceRef)currentSurface
{
    return CVPixelBufferGetIOSurface(frameQueue[currentQueueIdx].frameBuffer);
}

- (IOSurfaceID)currentSurfaceID{
    
    return IOSurfaceGetID(CVPixelBufferGetIOSurface(frameQueue[currentQueueIdx].frameBuffer));
}
#endif

- (id)currentFrame
{
    return (id)frameQueue[currentQueueIdx].frameBuffer;
}

- (id)getFrameAtTime: (NSTimeInterval)aTime
{
    OSSpinLockLock(&_movieLock);
    
    if	(qtMovie ) {
        NSInteger		ii;
        
        for (ii = 0; ii < maxQueueSize; ii++) {
            if (aTime < frameQueue[ii].frameTime - .005) {
                currentQueueIdx	= ii - 1;
                break;
            }
        }
        
        if (currentQueueIdx < 0)					// Time too back, give it the first
            currentQueueIdx	= 0;
        else if (currentQueueIdx == maxQueueSize)	// Time too forth, give it the last
            currentQueueIdx	= maxQueueSize - 1;
#ifdef	DEBUG
        NSLog(@"Found frame at %ld requested %.2f found: %.2f",
              currentQueueIdx, aTime, frameQueue[currentQueueIdx].frameTime);
#endif
    }
    
    OSSpinLockUnlock(&_movieLock);
    
    return (id)frameQueue[currentQueueIdx].frameBuffer;
}

- (void)releaseFrameQueue
{
    NSInteger	ii;
    
    for (ii = 0; ii < FRAME_QUEUE_SIZE; ii++) {
        if (frameQueue[ii].frameBuffer) {
            CVBufferRelease(frameQueue[ii].frameBuffer);
            frameQueue[ii].frameBuffer		= nil;
        }
        frameQueue[ii].frameTime	= 0.0;
    }
    currentQueueIdx = 0;
}

@end

@implementation MovieRenderer (FrameQueueHandling)

- (NSTimeInterval)refHostTime{
    return refHostTime;
}

- (void)setRefHostTime: (NSTimeInterval)aTime{
    refHostTime	= aTime;
}


- (void)addToFrameQueue: (CVImageBufferRef)currentFrame atTime: (NSTimeInterval)realTime
{
    NSDictionary	*attachmentValue	= (NSDictionary *)CVBufferGetAttachment(currentFrame, kCVBufferMovieTimeKey, NULL);
    NSTimeInterval	currentFrameTime	= [[attachmentValue objectForKey: (NSString *)kCVBufferTimeValueKey] doubleValue] /
    [[attachmentValue objectForKey: (NSString *)kCVBufferTimeScaleKey] doubleValue];
    NSInteger		ii;
    NSInteger		currentIdx			= 0;
    
    // Sometimes the frame time is NaN, so we should discard the resulting frame
    // Comparing NaN with itself gives false by definition
    if (currentFrameTime != currentFrameTime) {
#ifdef DEBUG
        //		NSLog(@"Discarding invalid frame time, realtime %.2f", realTime);
#endif
        CVBufferRelease(currentFrame);
        
        return;
    }
    
    OSSpinLockLock(&_movieLock);
    
    // Keep an ordered queue of frames
    if ((frameQueue[maxQueueSize - 1].frameBuffer) &&
        (frameQueue[maxQueueSize - 1].frameTime < currentFrameTime)) {
        // This is what will happen most of the times, make it fast
        currentIdx	= maxQueueSize - 1;
        
#ifdef DEBUG
        //		NSLog(@"Popping frame time at idx 0 timestamp %.2f...", frameQueue[0].frameTime);
#endif
        CVBufferRelease(frameQueue[0].frameBuffer);
        
        //reorder the index, shuffle them down
        for (ii = 0; ii < currentIdx; ii++)
            frameQueue[ii]	= frameQueue[ii + 1];
    } else {
        //if the last frame in the cue is greater in time than the current frame time
        
        for (ii = 0; ii < maxQueueSize; ii++) {
            
            if (!frameQueue[ii].frameBuffer) {
                // Buffer isn't full yet...
                currentIdx	= ii;
                break;
                
            } else if (frameQueue[ii].frameTime > currentFrameTime) {
                // Frames aren't necessarily ordered (i.e. H264 or so), reordering happens here
                if ((ii == 0) || (!frameQueue[maxQueueSize - 1].frameBuffer)) {
                    // Frame older than anyone else, or space in queue
                    // shift all down and clear last, if any
                    currentIdx	= ii;
                    
                    
                    if (frameQueue[maxQueueSize - 1].frameBuffer)
                        CVBufferRelease(frameQueue[maxQueueSize - 1].frameBuffer);
                    
                    for (ii = maxQueueSize - 1; ii > currentIdx; ii--)
                        frameQueue[ii]	= frameQueue[ii - 1];
                    
                    break;
                } else {
                    // We've finished the queue, pop first item and shift up
                    currentIdx	= ii - 1;
                    //#ifdef DEBUG
                    ////					NSLog(@"Substituting frame time at idx 0 timestamp %.2f...", frameQueue[0].frameTime);
                    //#endif
                    CVBufferRelease(frameQueue[0].frameBuffer);
                    
                    for (ii = 0; ii < currentIdx; ii++)
                        frameQueue[ii]	= frameQueue[ii + 1];
                    
                    break;
                }
                
            } else if (frameQueue[ii].frameTime == currentFrameTime) {
                // Duplicate frame
                //#ifdef DEBUG
                ////				NSLog(@"Discarding duplicate or old frame time at %.2f, realtime %.2f", currentFrameTime, realTime);
                //#endif
                CVBufferRelease(currentFrame);
                
                OSSpinLockUnlock(&_movieLock);
                
                return;
            }
        }
    }
    
    frameQueue[currentIdx].frameBuffer	= currentFrame;
    frameQueue[currentIdx].frameTime	= currentFrameTime;
    
    //#ifdef	DEBUG
    //	NSLog(@"Add frame at realTime %.2f idx %3ld timestamp %.2f, ", realTime, currentIdx, currentFrameTime);
    //#endif
    
    OSSpinLockUnlock(&_movieLock);
}

@end
