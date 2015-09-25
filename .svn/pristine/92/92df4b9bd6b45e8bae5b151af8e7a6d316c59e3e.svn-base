/*
 *  MovieRenderer.h
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

#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreVideo/CoreVideo.h>

// For OSAtomic operations
#import <libkern/OSAtomic.h>

//#define	DISABLE_IOSURFACE

#if defined(DISABLE_IOSURFACE) && defined(COREVIDEO_SUPPORTS_IOSURFACE)
#undef COREVIDEO_SUPPORTS_IOSURFACE
#define COREVIDEO_SUPPORTS_IOSURFACE	0
#endif

#define	FRAME_QUEUE_SIZE	100

typedef struct _QueueItem {
	CVImageBufferRef	frameBuffer;
	NSTimeInterval		frameTime;
} QueueItem;

@interface MovieRenderer : NSObject {
	QTMovie								*qtMovie;
	NSString							*moviePath;
	QTVisualContextRef					vContext;
    
    QTCaptureSession                    *captureSession;
    QTCaptureDeviceInput                *deviceInput;
    QTCaptureDecompressedVideoOutput	*videoOutput;
	
	OSSpinLock							_movieLock;
	NSInteger							maxQueueSize;
	NSInteger							currentQueueIdx;
	NSTimeInterval						refHostTime;
	NSTimeInterval						frameStep;
    
	QueueItem							frameQueue[FRAME_QUEUE_SIZE];
}

+ (void)setAudioDelay: (double)audioDelay;
+ (void)setAlphaSurface: (BOOL)doAlpha;

- (id)initWithDevice: (NSString *)uniqueID;
- (id)initWithPath: (NSString *)aPath;

- (void)startPlay;
- (void)stopAndReleaseMovie;
- (void)idle;

- (NSString *)moviePath;
- (NSTimeInterval)movieDuration;
- (NSTimeInterval)frameStep;
- (float)movieFrameRate;
- (NSTimeInterval)queuedMovieTime;

- (NSInteger)maxQueueSize;
- (void)setMaxQueueSize: (NSInteger)aSize;
- (float)movieRate;
- (void)setMovieRate: (float)aFloat;
- (float)movieVolume;
- (void)setMovieVolume: (float)aFloat;
- (NSTimeInterval)movieTime;
- (void)setMovieTime: (NSTimeInterval)aDouble;

- (NSDictionary *)pixelBufferAttributes;
#if COREVIDEO_SUPPORTS_IOSURFACE
- (IOSurfaceRef)currentSurface;
- (IOSurfaceID)currentSurfaceID;
#endif
- (id)currentFrame;
- (id)getFrameAtTime: (NSTimeInterval)aTime;
- (void)releaseFrameQueue;

@end
