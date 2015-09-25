/*
 *  IOSurfaceCLI.m
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

#import <Foundation/Foundation.h>
#import "MovieRenderer.h"
#import <mach/mach.h>

@interface MovieTest : NSObject {
	NSFileHandle	*standardOut;
	id				currentFrame;
	
	NSTimeInterval	timing;
}

- (void)getFrame: (NSTimer *)aTimer;

@end

@implementation MovieTest

- (id)init
{
	if (self = [super init]) {
		standardOut	= [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] retain];
		timing		= 0.0;
	}
	
	return self;
}


- (void)dealloc
{
	[standardOut release];
	
	[super dealloc];
}

- (void)getFrame: (NSTimer *)aTimer
{
	MovieRenderer	*theMovie	= [aTimer userInfo];
	id				newFrame	= [theMovie getFrameAtTime: timing];
	
	if (newFrame) {
		if (newFrame != currentFrame) {
			char		cmdStr[256];
			
#if COREVIDEO_SUPPORTS_IOSURFACE
			sprintf(cmdStr, "ID#%lu#\n", (unsigned long)[theMovie currentSurfaceID]);
#else
			sprintf(cmdStr, "F#%lu#\n", (unsigned long)[theMovie currentFrame]);
#endif
			[standardOut writeData: [NSData dataWithBytesNoCopy: cmdStr
														 length: strlen(cmdStr)
												   freeWhenDone: NO]];
			
			currentFrame	= newFrame;
		}
		
		timing	+= [aTimer timeInterval];
	}
}

@end

int main (int argc, const char * argv[])
{
    NSAutoreleasePool	*pool			= [[NSAutoreleasePool alloc] init];
	int					ch;
	BOOL				globalFlag		= NO;
	BOOL				useInputDevice	= NO;
	NSTimeInterval		timerStep		= -1.0;
	
	while ((ch = getopt(argc, (char * const *)argv, "gliad:r:")) != -1) {
		switch (ch) {
			case 'g':
				globalFlag	= YES;	// IOSurfaces will be global, unused for now
				break;
			case 'l':				// Lists input devices
				{
					NSArray			*inputDevices	= [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeVideo];
					NSEnumerator	*enumDevs		= [inputDevices objectEnumerator];
					QTCaptureDevice	*aDevice;
					
					while ((aDevice = [enumDevs nextObject]) != nil) {
						NSString		*deviceName	= [NSString stringWithFormat: @"\"%@\" ID: <%@>\n",
																				[aDevice localizedDisplayName],
																				[aDevice uniqueID]];
						NSFileHandle	*sOut	= (NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput];
						
						[sOut writeData: [deviceName dataUsingEncoding: NSUTF8StringEncoding]];
					}
				}
				break;
			case 'd':				// Sets audio delay
				[MovieRenderer setAudioDelay: atof(optarg)];
				break;
			case 'r':				// Sets video frame rate
				timerStep	= 1.0 / atof(optarg);
				break;
			case 'a':				// Sets alpha usage
				[MovieRenderer setAlphaSurface: YES];
				break;
			case 'i':				// Use input devices in place of a file
				useInputDevice	= YES;
				break;
		}
	}
	
	argc -= optind;
	argv += optind;
	
	if (useInputDevice || (argc >= 1)) {
		NSString		*moviePath	= nil;
		MovieTest		*movieTest	= [[MovieTest alloc] init];
		MovieRenderer	*theMovie	= nil;
		
		if (argv[0])
			moviePath	= [NSString stringWithUTF8String: argv[0]];
		
		if (useInputDevice) {
			theMovie	= [(MovieRenderer *)[MovieRenderer alloc] initWithDevice: moviePath];
		} else if ([[NSFileManager defaultManager] fileExistsAtPath: moviePath]) {
			theMovie	= [(MovieRenderer *)[MovieRenderer alloc] initWithPath: moviePath];
		}
		
		if (theMovie) {
			if (timerStep < 0.0)
				timerStep	= [theMovie frameStep];
			[NSTimer scheduledTimerWithTimeInterval: timerStep
											 target: movieTest
										   selector: @selector(getFrame:)
										   userInfo: theMovie
											repeats: YES];
			
			// Ensures play will start at next runloop turn
			[theMovie performSelector: @selector(startPlay) withObject: nil afterDelay: 0];
			
			[[NSRunLoop currentRunLoop] run];
		}
	}
	
    [pool drain];
    return 0;
}
