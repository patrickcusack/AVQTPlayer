/*
 *  IOSurfaceTestAppDelegate.m
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

#import "IOSurfaceTestAppDelegate.h"
#import "IOSurfaceTestView.h"
#import <QTKit/QTKit.h>

@implementation IOSurfaceTestAppDelegate

@synthesize window, moviePlayer, moviePath, view, playButton, fpsField;

- (void)dealloc
{
	if (_moviePlaying)
		[moviePlayer stopProcess];
	
	[inputRemainder release];
	[moviePath release];
	
	[frameCounterTimer invalidate];
	[frameCounterTimer release];
	
	[super dealloc];
}

- (void)_countFrames: (NSTimer *)aTimer
{
#pragma unused(aTimer)
	[fpsField setIntegerValue: numFrames];
	numFrames	= 0;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	frameCounterTimer	= [[NSTimer scheduledTimerWithTimeInterval: 1.0
															target: self
														  selector: @selector(_countFrames:)
														  userInfo: nil
														   repeats: YES] retain];
}

- (IBAction)chooseMovie: (id)sender
{
	NSOpenPanel *openPanel  = [NSOpenPanel openPanel];
	
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	if ([openPanel runModalForDirectory: nil
								   file: nil
								  types: [QTMovie movieFileTypes: QTIncludeCommonTypes]] == NSOKButton) {
		if (_moviePlaying) {
			[moviePlayer stopProcess];
			[playButton  setTitle: @"Play"];
		}
		self.moviePath	= [openPanel filename];
	} else {
		self.moviePath	= nil;
	}
}

- (IBAction)playMovie: (id)sender
{
	if (_moviePlaying) {
		[moviePlayer stopProcess];
		
		[sender setTitle: @"Play"];
	} else {
		NSString	*cliPath	= [[NSBundle mainBundle] pathForResource: @"IOSurfaceCLI" ofType: @""];
		NSArray		*args;
		
		if (self.moviePath && [self.moviePath length] > 1) {
			args		= [NSArray arrayWithObjects: cliPath, @"-g", self.moviePath, nil];
//			args		= [NSArray arrayWithObjects: cliPath, @"-g", @"-d", @"1.0", self.moviePath, nil];
		} else {
			args		= [NSArray arrayWithObjects: cliPath, @"-g", @"-i", nil];
		}
		
		if (moviePlayer	= [[TaskWrapper alloc] initWithController: self arguments: args userInfo: nil])
			[moviePlayer startProcess];
		else
			NSLog(@"Can't launch %@!", cliPath);
		
		[sender setTitle: @"Stop"];
	}

}

- (void)appendOutput:(NSString *)output fromProcess: (TaskWrapper *)aTask
{
	if (!inputRemainder)
		inputRemainder	= [[NSString alloc] initWithString:@""];
	
	NSArray			*outComps	= [[inputRemainder stringByAppendingString: output] componentsSeparatedByString: @"\n"];
	NSEnumerator	*enumCmds	= [outComps objectEnumerator];
	NSString		*cmdStr;
	
	while ((cmdStr = [enumCmds nextObject]) != nil) {
		if (([cmdStr length] > 3) && [[cmdStr substringToIndex: 3] isEqualToString: @"ID#"]) {
			long			surfaceID	= 0;
			
			sscanf([cmdStr UTF8String], "ID#%ld#", &surfaceID);
			if (surfaceID) {
				[view setSurfaceID: surfaceID];
				[view setNeedsDisplay: YES];
				numFrames++;
			}
		}
	}
	
	cmdStr	= [outComps lastObject];
	if (([cmdStr length] > 0) && ([cmdStr characterAtIndex: [cmdStr length] - 1] != '#')) {
		NSLog(@"Storing %@ for later concat", cmdStr);
		[inputRemainder release];
		inputRemainder	= [cmdStr retain];
	}
}

- (void)processStarted: (TaskWrapper *)aTask
{
	_moviePlaying	= YES;
}

- (void)processFinished: (TaskWrapper *)aTask withStatus: (int)statusCode
{
	_moviePlaying	= NO;
	
	[moviePlayer autorelease];
	moviePlayer		= nil;
}

@end
