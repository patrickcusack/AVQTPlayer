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

static double	gAudioDelay	= 0.0;
static BOOL		gUseAlpha	= NO;

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
		NSLog(@"Error %d getting frame at %.2f", err, realTime);
	}
	
	[pool release];
}

@implementation MovieRenderer

+ (void)setAudioDelay: (double)audioDelay
{
	if (audioDelay >= 0.0)
		gAudioDelay = audioDelay;
}

+ (void)setAlphaSurface: (BOOL)doAlpha
{
	gUseAlpha	= doAlpha;
}

- (id)initWithDevice: (NSString *)uniqueID
{
	if ([super init]) {
        QTCaptureDevice *device	= nil;
		NSError			*error	= nil;
		
        captureSession	= [[QTCaptureSession alloc] init];
        
		if (uniqueID && ([uniqueID length] > 1))
			device = [QTCaptureDevice deviceWithUniqueID: uniqueID];
		else
			device = [QTCaptureDevice defaultInputDeviceWithMediaType: QTMediaTypeVideo];
		
        if (![device open: &error]) {
            NSLog(@"QTCaptureDevice error: %@", [error localizedDescription]);
			[self release];
            return nil;
        }
        
        // Add a device input for that device to the capture session
        deviceInput = [[QTCaptureDeviceInput alloc] initWithDevice: device];
        if (![captureSession addInput: deviceInput error: &error]) {
            NSLog(@"QTCaptureDeviceInput error: %@", [error localizedDescription]);
			[self release];
            return nil;
        }
        
        // Add a decompressed video output that returns raw frames to the session
        videoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
		[videoOutput setPixelBufferAttributes: [self pixelBufferAttributes]];
        [videoOutput setDelegate: self];
        if (![captureSession addOutput: videoOutput error: &error]) {
            NSLog(@"QTCaptureDecompressedVideoOutput error: %@", [error localizedDescription]);
			[self release];
            return nil;
        }
        
        // Start the session
        [captureSession startRunning];
		
#if (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_6) && \
	(QTKIT_VERSION_MIN_REQUIRED <= QTKIT_VERSION_7_6_3)
		frameStep = [videoOutput minimumVideoFrameInterval];
#endif
		if (frameStep < 0.005)
			frameStep	= 1.0 / 30.0;
		
		refHostTime			= -1.0;
		maxQueueSize	= 16;
		_movieLock		= OS_SPINLOCK_INIT;
	}
	
	return self;
}

- (id)initWithPath: (NSString *)aPath
{
	if ([super init]) {
		BOOL			hasAudio	= (gAudioDelay > 0.0);
		NSDictionary	*ctxAttrs	= [NSDictionary dictionaryWithObjectsAndKeys: [self pixelBufferAttributes], kQTVisualContextPixelBufferAttributesKey,
																				[NSNumber numberWithFloat: gAudioDelay], kQTVisualContextExpectedReadAheadKey,
																				nil];
		NSDictionary	*movieAttrs	= [NSDictionary dictionaryWithObjectsAndKeys: aPath, QTMovieFileNameAttribute,
																				[NSNumber numberWithBool: hasAudio], QTMovieEditableAttribute,
																				[NSNumber numberWithFloat: 1.0], QTMovieVolumeAttribute,
//																				[NSNumber numberWithBool: YES], QTMovieDontInteractWithUserAttribute,
																				[NSNumber numberWithBool: YES], QTMovieOpenAsyncOKAttribute,
																				nil];
		
		QTPixelBufferContextCreate(kCFAllocatorDefault, (CFDictionaryRef)ctxAttrs, &vContext);
		
		moviePath	= [aPath copy];
		
		if (qtMovie = [[QTMovie alloc] initWithAttributes: movieAttrs error: nil]) {
			NSUInteger	playHints	= hintsHighQuality;
			Movie		inMovie		= [qtMovie quickTimeMovie];
			TimeScale	tScale		= GetMovieTimeScale(inMovie);
			
			[qtMovie gotoBeginning];
			refHostTime	= -1.0;
			
			if (hasAudio && [[qtMovie attributeForKey: QTMovieHasAudioAttribute] boolValue]) {
				NSArray			*audioTracks	= [qtMovie tracksOfMediaType: QTMediaTypeSound];
				
				if ([audioTracks count] > 0) {
					QTTime		insertionPoint	= QTMakeTime(0, tScale);
					QTTime		durationTime	= QTMakeTime((long long)(gAudioDelay * (double)tScale), tScale);
					QTTimeRange	timeRange		= QTMakeTimeRange(insertionPoint, durationTime);
					NSInteger	ii, numTracks	= [audioTracks count];
					
					for (ii = 0; ii < numTracks; ii++)
						[[audioTracks objectAtIndex: ii] insertEmptySegmentAt: timeRange];
				}
			}
			
			SetMovieVisualContext(inMovie, vContext);
			SetMoviePlayHints(inMovie, playHints, playHints);
			PrePrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie), NULL, NULL);
			PrerollMovie(inMovie, GetMovieTime(inMovie, NULL), GetMoviePreferredRate(inMovie));
			
			[qtMovie setRate: 0.0];
			
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
			
			[self idle];
		}
		
		maxQueueSize	= 16;
		_movieLock		= OS_SPINLOCK_INIT;
	}
	return self;
}

- (void)dealloc
{
	[self stopAndReleaseMovie];
	
	if (vContext) {
		QTVisualContextRelease(vContext);
	} else if (captureSession) {
		[captureSession release];
		[deviceInput release];
		[videoOutput release];
	}
	
	[moviePath release];
	
	
	[super dealloc];
}

- (void)startPlay
{
	// This stops the movie!!!!
//	[qtMovie setAttribute: [NSNumber numberWithBool: YES]
//				   forKey: QTMoviePlaysAllFramesAttribute];
	if (![[qtMovie attributeForKey: QTMoviePlaysAllFramesAttribute] boolValue])
		NSLog(@"Warning: movie will not play all frames!");
	[self setMovieRate: 1.0];
}

- (void)stopAndReleaseMovie
{
	if (qtMovie) {
		[qtMovie stop];
		QTVisualContextSetImageAvailableCallback(vContext, NULL, NULL);
		SetMovieVisualContext([qtMovie quickTimeMovie], NULL);
		[qtMovie release];
		qtMovie = nil;
	} else if (captureSession && [captureSession isRunning]) {
		QTCaptureDevice *device = [deviceInput device];
		
		[captureSession stopRunning];
		
		if ([device isOpen])
			[device close];    
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


- (float)movieRate
{
	if (qtMovie)
		return [qtMovie rate];
	else
		return 0.0;
}

- (void)setMovieRate: (float)aFloat
{
	if (qtMovie)
		[qtMovie setRate: aFloat];
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
#else
	NSMutableDictionary	*pbAttrs	= [NSMutableDictionary dictionaryWithCapacity: 1];
#endif
	
	if (gUseAlpha)
		[pbAttrs setObject: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA]
					forKey: (NSString *)kCVPixelBufferPixelFormatTypeKey];
	else
 		[pbAttrs setObject: [NSNumber numberWithInt: kCVPixelFormatType_422YpCbCr8]
					forKey: (NSString *)kCVPixelBufferPixelFormatTypeKey];
	
	return pbAttrs;
}

#if COREVIDEO_SUPPORTS_IOSURFACE
- (IOSurfaceRef)currentSurface
{
	return CVPixelBufferGetIOSurface(frameQueue[currentQueueIdx].frameBuffer);
}

- (IOSurfaceID)currentSurfaceID
{
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
	
	if	(qtMovie || (captureSession && [captureSession isRunning])) {
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


// This delegate method is called whenever the QTCaptureDecompressedVideoOutput receives a frame
- (void)captureOutput: (QTCaptureOutput *)captureOutput
  didOutputVideoFrame: (CVImageBufferRef)videoFrame
	 withSampleBuffer: (QTSampleBuffer *)sampleBuffer
	   fromConnection: (QTCaptureConnection *)connection
{
	NSTimeInterval		realTime	= 0.0;
	NSMutableDictionary	*timeDict	= [NSMutableDictionary dictionaryWithCapacity: 2];
	
	realTime = (double)AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()) / 1000000000.0;
	
	if (refHostTime <= 0.0)
		refHostTime	= realTime;
	
	realTime	-= refHostTime;
	[timeDict setObject: [NSNumber numberWithInteger: 600]
				 forKey: (NSString *)kCVBufferTimeScaleKey];
	[timeDict setObject: [NSNumber numberWithInteger: (NSInteger)(realTime * 600.0)]
				 forKey: (NSString *)kCVBufferTimeValueKey];
	CVBufferSetAttachment(videoFrame, kCVBufferMovieTimeKey, (CFDictionaryRef)timeDict, kCVAttachmentMode_ShouldPropagate);
	CVBufferRetain(videoFrame);
	
	[self addToFrameQueue: videoFrame atTime: realTime];
}

@end

@implementation MovieRenderer (FrameQueueHandling)

- (NSTimeInterval)refHostTime
{
	return refHostTime;
}

- (void)setRefHostTime: (NSTimeInterval)aTime
{
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
		
		for (ii = 0; ii < currentIdx; ii++)
			frameQueue[ii]	= frameQueue[ii + 1];
	} else {
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
#ifdef DEBUG
//					NSLog(@"Substituting frame time at idx 0 timestamp %.2f...", frameQueue[0].frameTime);
#endif
					CVBufferRelease(frameQueue[0].frameBuffer);
						
					for (ii = 0; ii < currentIdx; ii++)
						frameQueue[ii]	= frameQueue[ii + 1];

					break;
				}
			} else if (frameQueue[ii].frameTime == currentFrameTime) {
				// Duplicate frame
#ifdef DEBUG
//				NSLog(@"Discarding duplicate or old frame time at %.2f, realtime %.2f", currentFrameTime, realTime);
#endif
				CVBufferRelease(currentFrame);
				
				OSSpinLockUnlock(&_movieLock);
				
				return;
			}
		}
	}
	
	frameQueue[currentIdx].frameBuffer	= currentFrame;
	frameQueue[currentIdx].frameTime	= currentFrameTime;
	
#ifdef	DEBUG
	NSLog(@"Add frame at realTime %.2f idx %3ld timestamp %.2f, ", realTime, currentIdx, currentFrameTime);
#endif
	
	OSSpinLockUnlock(&_movieLock);
}

@end
