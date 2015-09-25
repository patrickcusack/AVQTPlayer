//
//  PCMovieRenderObject.m
//  IOSurfaceTest
//
//  Created by Patrick Cusack on 5/7/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "PCMovieRenderObject.h"
#import "QTMovie_Extension.h"

@interface QTMovie (QTFrom763)
- (QTTime)frameStartTime: (QTTime)atTime;
- (QTTime)frameEndTime: (QTTime)atTime;
- (QTTime)keyframeStartTime:(QTTime)atTime;
@end

@interface PCMovieRenderObject (FrameQueueHandling)
- (void)addToFrameQueue: (CVImageBufferRef)currentFrame atTime: (NSTimeInterval)aTime;
@end

static void frameAvailable(QTVisualContextRef vContext, const CVTimeStamp *frameTime, void *refCon){

    PCMovieRenderObject		*renderer	= (PCMovieRenderObject *)refCon;
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

@implementation PCMovieRenderObject
@synthesize qtMovie;
@synthesize moviePath;
@synthesize proxyMoviePath;
@synthesize refHostTime;
@synthesize isMoviePlaying;
@synthesize nextInterestingDuration;
@synthesize nominalFrameRate;
@synthesize audioHasLoaded;

#pragma mark -

- (id)init{
    if ([super init]) {

    }
    return self;
}

- (void)addAudioFileToCurrentMovie:(NSURL*)audioURL{
    
    if (![self qtMovie]) {
        return;
    }
    
    NSString * originalMoviePath = [self moviePath];
    
    [self setAudioHasLoaded:NO];
    
    QTMovie *newRefMovie = [QTMovie movieWithAttributes:nil error:NULL];
    [newRefMovie setAttribute:[NSNumber numberWithBool:YES]  forKey:QTMovieEditableAttribute];
    
    // open the files that contain the sound and video
    QTMovie *pixMovie = [QTMovie movieWithFile:[self moviePath] error:nil];
    QTTimeRange pixQTRange = QTMakeTimeRange(QTZeroTime, [pixMovie duration]);
    
    QTMovie *audioMovie = [QTMovie movieWithFile:[audioURL path] error:nil];
    QTTimeRange audioQTRange = QTMakeTimeRange(QTZeroTime, [audioMovie duration]);
    
    //we are adding the audio movie
    [newRefMovie insertSegmentOfMovie:audioMovie timeRange:audioQTRange atTime:QTZeroTime];
    
    // create the destination track and media
    QTTrack *			dstQTTrack = nil;
    Track				dstTrack = NULL;
    Track				srcTrack = NULL;
    Media				dstMedia = NULL;
    Media				pixMovieMedia = [[[pixMovie firstVideoTrack] media] quickTimeMedia];
    
    srcTrack = [[pixMovie firstVideoTrack] quickTimeTrack];
    dstTrack = NewMovieTrack([newRefMovie quickTimeMovie], (short)480 << 16, (short)320 << 16, (short)(1 * 256.0));
    CopyTrackSettings(srcTrack, dstTrack);
    
    dstMedia = NewTrackMedia(dstTrack, VideoMediaType, GetMediaTimeScale(pixMovieMedia), NULL, 0);
    
    if (dstTrack && dstMedia) {
        dstQTTrack = [QTTrack trackWithQuickTimeTrack:dstTrack error:nil];
        if (dstQTTrack) {
            [dstQTTrack insertSegmentOfTrack:[[pixMovie tracks] objectAtIndex:0] timeRange:pixQTRange atTime:QTZeroTime];
        }
    }

    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"file.mov"];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    NSError * e = nil;
    [newRefMovie writeToFile:[fileURL path] withAttributes:nil error:&e];
    [self loadMovieURL:fileURL];
    
    [self setProxyMoviePath:[fileURL path]];
    [self setMoviePath:originalMoviePath];
    [self setAudioHasLoaded:YES];
}

- (void)loadMovieURL:(NSURL*)movieURL{
    
    [self setMoviePath:[movieURL path]];
    [self setProxyMoviePath:nil];
    
    NSDictionary	*ctxAttrs	= [NSDictionary dictionaryWithObjectsAndKeys: [self pixelBufferAttributes], kQTVisualContextPixelBufferAttributesKey,
                                   [NSNumber numberWithFloat: 0.0], kQTVisualContextExpectedReadAheadKey,
                                   nil];
    
    NSDictionary	* movieAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], QTMovieRateChangesPreservePitchAttribute,
                                    [NSNumber numberWithBool:NO], QTMovieOpenAsyncOKAttribute,
                                    [self moviePath], QTMovieFileNameAttribute,
                                    nil];
    
    QTMovie * nMovie = [[[QTMovie alloc] initWithAttributes: movieAttrs error:nil] autorelease];
    [self setQtMovie:nMovie];
    
    if ([self qtMovie]) {
        NSUInteger	playHints	= hintsHighQuality;
        Movie		inMovie		= [[self qtMovie] quickTimeMovie];
        TimeScale	tScale		= GetMovieTimeScale(inMovie);
        
        [[self qtMovie] updateMovieTimeScaleToMatchFirstVideTrackTimeScale];
        
        [[self qtMovie] gotoBeginning];
        
        refHostTime	= -1.0;
        
        QTPixelBufferContextCreate(kCFAllocatorDefault, (CFDictionaryRef)ctxAttrs, &vContext);
        
        SetMovieVisualContext(inMovie, vContext);
        SetMoviePlayHints(inMovie, playHints, playHints);
        PrePrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie), NULL, NULL);
        PrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie));
        
        [self setNextInterestingDuration:(SInt32)[self getNextInterestingDuration]];
        [self setNominalFrameRate:[self getNominalFrameRate]];
        
        if ([qtMovie respondsToSelector: @selector(frameEndTime:)]) {
            // Only on QT 7.6.3
            QTTime	qtStep	= [qtMovie frameEndTime: QTMakeTime(0, tScale)];
            QTGetTimeInterval (qtStep, &_frameStep);
        } else {
            [[self qtMovie] stepForward];
            QTGetTimeInterval ([qtMovie currentTime], &_frameStep);
            [[self qtMovie] gotoBeginning];
        }
        
        QTVisualContextSetImageAvailableCallback(vContext, frameAvailable, self);
        
        //this primes the buffers to begin decoding
        [[self qtMovie] setRate:0.1];
        [[self qtMovie] setRate:0.0];
        [[self qtMovie] gotoBeginning];
    }
    
    maxQueueSize	= 1;
    _movieLock		= OS_SPINLOCK_INIT;
    
    [self setIsMoviePlaying:NO];
}


- (TimeValue)getNextInterestingDuration{
    
    QTTime currentTime = [[self qtMovie] currentTime];

    OSType myTypes[1];
    myTypes[0] = VisualMediaCharacteristic;
    
    TimeValue nInteresting;
    TimeValue nInterestingDuration;
    
    GetMovieNextInterestingTime([[self qtMovie] quickTimeMovie],
                                nextTimeStep,
                                1,
                                myTypes,
                                currentTime.timeValue,
                                1,
                                &nInteresting,
                                &nInterestingDuration);
    
    return nInterestingDuration;
}

- (float)getNominalFrameRate{
    QTTime currentTime = [[self qtMovie] currentTime];
    TimeValue nInterestingDuration = [self getNextInterestingDuration];
    return (1.0 * currentTime.timeScale/nInterestingDuration);
}

- (void)unloadMovie{

    [self setMoviePath:nil];
    [self setProxyMoviePath:nil];
    
    if ([self qtMovie]) {
        
        [[self qtMovie] stop];
        QTVisualContextSetImageAvailableCallback(vContext, NULL, NULL);
        SetMovieVisualContext([[self qtMovie] quickTimeMovie], NULL);
        [self setQtMovie:nil];
    }
    
    [self releaseFrameQueue];
    
    if (vContext) {
        QTVisualContextRelease(vContext);
        vContext = NULL;
    }

}

- (void)dealloc{
    [self unloadMovie];
    [super dealloc];
}

- (void)play{
    [self setMovieIsPlaying:YES];
}

- (void)pause{
    [self setMovieIsPlaying:NO];
}

- (void)setMovieIsPlaying:(BOOL)flag{

    if (![self qtMovie]) {
        return;
    }
    
    if ([self isMoviePlaying] == YES) {
        [[self qtMovie] stop];
        [self setIsMoviePlaying:NO];
    } else{
        [self setMovieRate: 1.0];
        [self setIsMoviePlaying:YES];
    }
}

-(void)goToBeginning{
    if (![self qtMovie]) {
        return;
    }
    
    [[self qtMovie] gotoBeginning];
}

- (void)goToEnd{
    if (![self qtMovie]) {
        return;
    }
    
    [[self qtMovie] gotoEnd];
}

- (oneway void)goToTimeValue:(long)timeValue{
    if (![self qtMovie]) {
        return;
    }
    
    QTTime cTime = [qtMovie currentTime];
    QTTime nTime;
    nTime.timeValue = timeValue;
    nTime.timeScale = cTime.timeScale;
    nTime.flags = cTime.flags;
    
    [[self qtMovie] setCurrentTime:nTime];
}

- (void)setMovieRate:(float)nRate{
    if (![self qtMovie]) {
        return;
    }
    
    [[self qtMovie] setRate:nRate];
}

- (float)movieRate{
    
    if ([self qtMovie])
        return [[self qtMovie] rate];
    else
        return 0.0;
}

- (void)stepForward{
    if (![self qtMovie]) {
        return;
    }
    
    [[self qtMovie] stepForward];
}

- (void)stepBackward{
    if (![self qtMovie]) {
        return;
    }
    
    [[self qtMovie] stepBackward];
}

- (NSValue*)movieSize{
    if (![self qtMovie]) {
        return nil;
    }
    
    return [[[self qtMovie] movieAttributes] valueForKey:QTMovieNaturalSizeAttribute];
}

- (long long)currentTimeValue{
    if (![self qtMovie]) {
        return 0;
    }
    return [[self qtMovie] currentTime].timeValue;
}

- (long long)maxTimeValue{
    if (![self qtMovie]) {
        return 0;
    }
    return [[[self qtMovie] attributeForKey:QTMovieDurationAttribute] QTTimeValue].timeValue;
}

- (long)timeScale{
    if (![self qtMovie]) {
        return 0;
    }
    return [[[self qtMovie] attributeForKey:QTMovieDurationAttribute] QTTimeValue].timeScale;
}


- (void)idle{
    if (vContext)
        QTVisualContextTask(vContext);
}

- (NSTimeInterval)movieDuration{
    if ([self qtMovie]) {
        QTTime qtDuration	= [[self qtMovie] duration];
        return (double)qtDuration.timeValue / (double)qtDuration.timeScale;
    }
    
    return 0;
}

- (NSTimeInterval)frameStep{
    return _frameStep;
}

- (float)movieFrameRate {
    
    if (_frameStep > 0.0)
        return 1.0 / _frameStep;
    
    return 0.0;
}

- (NSTimeInterval)queuedMovieTime {
    return _frameStep * maxQueueSize;
}

- (NSInteger)maxQueueSize{
    return maxQueueSize;
}


- (NSTimeInterval)movieTime{
    if ([self qtMovie]) {
        
        NSTimeInterval	currentTime;
        QTGetTimeInterval([qtMovie currentTime], &currentTime);
        return currentTime;
        
    } else {
        return 0.0;
    }
}

- (void)setMovieTime: (NSTimeInterval)aDouble {
    
    if ([self qtMovie]) {
        [[self qtMovie] setCurrentTime: QTMakeTimeWithTimeInterval(aDouble)];
    }
}

- (NSDictionary *)pixelBufferAttributes{
    
    NSDictionary		*ioAttrs	= [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                         forKey: (NSString *)kIOSurfaceIsGlobal];
    NSMutableDictionary	*pbAttrs	= [NSMutableDictionary dictionaryWithObject: ioAttrs
                                                                      forKey: (NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [pbAttrs setObject: [NSNumber numberWithInt: kCVPixelFormatType_422YpCbCr8]
                forKey: (NSString *)kCVPixelBufferPixelFormatTypeKey];
    return pbAttrs;
}

#if COREVIDEO_SUPPORTS_IOSURFACE
- (IOSurfaceRef)currentSurface {
    return CVPixelBufferGetIOSurface(frameQueue[currentQueueIdx].frameBuffer);
}

- (IOSurfaceID)currentSurfaceID{
    return IOSurfaceGetID(CVPixelBufferGetIOSurface(frameQueue[currentQueueIdx].frameBuffer));
}
#endif

-(IOSurfaceID)hasNewFrameAtTime:(NSTimeInterval)time{
    
    id newFrame	= [self getFrameAtTime: time];
    
    if (newFrame) {
        if (newFrame != _currentFrame) {
            _currentFrame = newFrame;
            return [self currentSurfaceID];
        }
    }
    
    return UINT32_MAX;
}

- (id)currentFrame{
    return (id)frameQueue[currentQueueIdx].frameBuffer;
}

- (id)getFrameAtTime: (NSTimeInterval)aTime{
    OSSpinLockLock(&_movieLock);
    
    if	([self qtMovie]) {
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
    }
    
    OSSpinLockUnlock(&_movieLock);
    
    return (id)frameQueue[currentQueueIdx].frameBuffer;
}

- (void)releaseFrameQueue{
    
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

@implementation PCMovieRenderObject (FrameQueueHandling)


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
        CVBufferRelease(currentFrame);
        return;
    }
    
    OSSpinLockLock(&_movieLock);
    
    // Keep an ordered queue of frames
    if ((frameQueue[maxQueueSize - 1].frameBuffer) &&
        (frameQueue[maxQueueSize - 1].frameTime < currentFrameTime)) {
        // This is what will happen most of the times, make it fast
        currentIdx	= maxQueueSize - 1;
        
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

    OSSpinLockUnlock(&_movieLock);
}

@end
