/*
 *  IOSurfaceTestAppDelegate.h
 *  IOSurfaceTest
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

#import <Cocoa/Cocoa.h>
#import "TaskWrapper.h"
#import "PCScrubber.h"
#import "PCProxyProtocol.h"
#import "IOSurfaceView.h"
#import "IOSurfaceLayer.h"

@interface IOSurfaceMovieController : NSObject <NSApplicationDelegate, TaskWrapperController, PCScrubberProxy,IOSurfaceTestViewDragController, NSWindowDelegate>{
    NSWindow			*window;
	IOSurfaceView       *view;
	NSButton			*playButton;
	NSTextField			*fpsField;
	
	TaskWrapper			*moviePlayer;
	NSString			*moviePath;
	NSString			*inputRemainder;
	
	NSInteger			numFrames;
	NSTimer				*frameCounterTimer;
	
	BOOL				_moviePlaying;
    id                  movieProxy;
    unsigned long       maxMoviePosition;
    unsigned long       currentMoviePosition;
    NSSize              movieSizeForView;
    
    IOSurfaceLayer      *surfaceLayer;
}

- (void)loadMovieURL:(NSURL*)url;

- (IBAction)chooseMovie: (id)sender;
- (void)getMovieInfo;

- (IBAction)goToTime:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)goToBeginning:(id)sender;
- (IBAction)gotoEnd:(id)sender;
- (IBAction)setRate:(id)sender;


- (void)appendOutput:(NSString *)output fromProcess: (TaskWrapper *)aTask;
- (void)processStarted: (TaskWrapper *)aTask;
- (void)processFinished: (TaskWrapper *)aTask withStatus: (int)statusCode;


@property (assign) IBOutlet NSWindow			*window;
@property (assign) IBOutlet IOSurfaceView	*view;
@property (assign) IBOutlet NSButton			*playButton;
@property (assign) IBOutlet NSTextField			*fpsField;
@property (assign) IBOutlet NSSlider            *positionSlider;
@property (assign) IBOutlet PCScrubber          *rateSlider;


@property (nonatomic, readwrite,retain) TaskWrapper *moviePlayer;
@property (nonatomic, readwrite,retain) NSString *moviePath;
@property (nonatomic, readwrite, retain) id movieProxy;
@property (nonatomic, assign) unsigned long maxMoviePosition;
@property (nonatomic, assign) unsigned long currentMoviePosition;
@property (nonatomic, assign) NSSize movieSizeForView;
@property (nonatomic, readwrite, retain) IOSurfaceLayer *surfaceLayer;
@property (assign) IBOutlet NSView *scratchView;
@property (assign) IBOutlet NSView *testView;

@end
