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

#import "IOSurfaceMovieController.h"
#import "IOSurfaceView.h"
#import <QTKit/QTKit.h>

#define USELAYER 1

@implementation IOSurfaceMovieController

@synthesize window;
@synthesize moviePlayer;
@synthesize moviePath;
@synthesize view;
@synthesize playButton;
@synthesize fpsField;
@synthesize movieProxy;
@synthesize currentMoviePosition;
@synthesize maxMoviePosition;
@synthesize movieSizeForView;
@synthesize surfaceLayer;

+ (NSString*)uuid{
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [uuidString autorelease];
}

- (void)dealloc
{
	if (_moviePlaying)
		[moviePlayer stopProcess];
	
	[inputRemainder release];
	[moviePath release];
	
	[frameCounterTimer invalidate];
	[frameCounterTimer release];
    
    if (USELAYER) {
        [[self surfaceLayer] removeFromSuperlayer];
        [self setSurfaceLayer:nil];
    }
    
    [self setMovieProxy:nil];
	[super dealloc];
}

- (void)_countFrames: (NSTimer *)aTimer{
#pragma unused(aTimer)
	[fpsField setIntegerValue: numFrames];
	numFrames	= 0;
    
    if ([self movieProxy]) {
        [[self positionSlider] setDoubleValue:[[self movieProxy] currentTimeValue]];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	frameCounterTimer	= [[NSTimer scheduledTimerWithTimeInterval: 1.0
															target: self
														  selector: @selector(_countFrames:)
														  userInfo: nil
														   repeats: YES] retain];
 
    [self launchHelper];
    
    [(PCScrubber*)[self rateSlider] setDelegate:self];
    
    
    if (USELAYER) {
        NSRect nFrame = [[self view] frame];
        NSUInteger mask = [[self view] autoresizingMask];
        [[self view] removeFromSuperview];
        
        [[self scratchView] setWantsLayer:YES];
        [[[self scratchView] layer] setBorderColor:CGColorGetConstantColor(kCGColorWhite)];
        [[[self scratchView] layer] setBorderWidth:3.0];
        [[self scratchView] setFrame:nFrame];
        [[self scratchView] setAutoresizingMask:mask];
        
        [self setSurfaceLayer:[[[IOSurfaceLayer alloc] init] autorelease]];
        [[self surfaceLayer] setBounds:[[self scratchView] bounds]];
        [[self surfaceLayer] setPosition:CGPointMake(CGRectGetMidX([[self scratchView] bounds]), CGRectGetMidY([[self scratchView] bounds]))];
        [[self surfaceLayer] setNeedsDisplay];
        [[[self scratchView] layer] addSublayer:[self surfaceLayer]];
        [[[self scratchView] layer] setNeedsDisplay];
        
        
        [[self window] setDelegate:self];
        
        [[self scratchView] addSubview:[self testView]];
        [[self testView] setFrameOrigin:[[self scratchView] bounds].origin];
        
    } else {
        
        [[self view] setController:self];
        
    }
    
    
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[self movieProxy] addMovieURL:[NSURL fileURLWithPath:@"/Users/patrickcusack/Documents/swtfa-358fz9G-tlr1_1080pDNxHD.mov"]];
//        [self getMovieInfo];
//        [[self movieProxy] setMovieIsPlaying:YES];
//    });
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[self movieProxy] addMovieURL:[NSURL fileURLWithPath:@"/Users/patrickcusack/Documents/DeveloperShare/VT_R1v0317_PIX.mov"]];
//        [self getMovieInfo];
//        [[self movieProxy] setMovieIsPlaying:YES];
//    });
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[self movieProxy] addMovieURL:[NSURL fileURLWithPath:@"/Users/patrickcusack/Documents/swtfa-358fz9G-tlr1_1080pDNxHD.mov"]];
//        [self getMovieInfo];
//        [[self movieProxy] setMovieIsPlaying:YES];
//    });
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(90.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[self movieProxy] addMovieURL:[NSURL fileURLWithPath:@"/Users/patrickcusack/Documents/DeveloperShare/VT_R1v0317_PIX.mov"]];
//        [self getMovieInfo];
//        [[self movieProxy] setMovieIsPlaying:YES];
//    });
    
}

- (void)applicationWillTerminate:(NSNotification *)notification{
    [[self movieProxy] quitHelperTool];
    [self setMovieProxy:nil];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize{
    if (USELAYER) {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

        [[self surfaceLayer] setBounds:[[self scratchView] bounds]];
        [[self surfaceLayer] setPosition:CGPointMake(CGRectGetMidX([[self scratchView] bounds]), CGRectGetMidY([[self scratchView] bounds]))];
        [[self surfaceLayer] setNeedsDisplay];
        
        [CATransaction commit];
    }
    return frameSize;
}

- (void)handleDragURL:(NSURL *)dragURL{
    [self loadMovieURL:dragURL];
}

- (void)loadMovieURL:(NSURL*)url{
    [[self movieProxy] addMovieURL:url];
    [self getMovieInfo];
}

- (void)getMovieInfo{
    if ([[self movieProxy] hasMovie]) {
        [self setCurrentMoviePosition:0];
        [self setMaxMoviePosition:[[self movieProxy] maxTimeValue]];
        [[self positionSlider] setDoubleValue:0.0];
        [[self positionSlider] setMaxValue:[self maxMoviePosition]];
        
        if (USELAYER) {
            [self setMovieSizeForView:[[[self movieProxy] movieSize] sizeValue]];
            [[self surfaceLayer] setMovieSize:[self movieSizeForView]];
        } else {
            [self setMovieSizeForView:[[[self movieProxy] movieSize] sizeValue]];
            [[self view] setMovieSize:[self movieSizeForView]];
        }
    }
}

- (IBAction)playMovie: (id)sender{
    
    if ([[self movieProxy] hasMovie]) {
        if ([[self movieProxy] isMoviePlaying]) {
            [[self movieProxy] setMovieIsPlaying:NO];
            [(NSButton*)sender setTitle:@"Play"];
        } else {
            [[self movieProxy] setMovieIsPlaying:YES];
            [(NSButton*)sender setTitle:@"Stop"];
        }
    }
}

- (IBAction)forward:(id)sender {
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] forward];
    }
}

- (IBAction)back:(id)sender {
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] back];
    }
}

- (IBAction)goToBeginning:(id)sender {
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToBeginning];
    }
}

- (IBAction)gotoEnd:(id)sender{
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] gotoEnd];
    }
}

- (IBAction)setRate:(id)sender {

    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] setMovieRate:[sender floatValue]];
    }
}

- (IBAction)goToTime:(id)sender{
    long newTime = (long)[sender doubleValue];
    
    if ([[self movieProxy] hasMovie]) {
        [[self movieProxy] goToTimeValue:newTime];
    }
}

- (IBAction)chooseMovie: (id)sender
{
	NSOpenPanel *openPanel  = [NSOpenPanel openPanel];
	
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
    
    [openPanel setAllowedFileTypes:@[@"mov", @"mp4"]];
    [openPanel beginWithCompletionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSOKButton:
                self.moviePath	= [[openPanel URL] path];
                [self loadMovieURL:[openPanel URL]];
                break;
            default:
                self.moviePath	= nil;
                break;
        }
    }];
}

- (void)launchHelper{
    
    NSString	*cliPath	= [[NSBundle mainBundle] pathForResource: @"IOSurfaceCLI" ofType: @""];
    NSString    *taskUUIDForDOServer = [IOSurfaceMovieController uuid];
    NSArray		*args       = [NSArray arrayWithObjects:cliPath,taskUUIDForDOServer, nil];
    
    moviePlayer	= [[TaskWrapper alloc] initWithController: self arguments: args userInfo: nil];
    
    if (moviePlayer){
        [moviePlayer startProcess];
    }  else {
        NSLog(@"Can't launch %@!", cliPath);
    }
    
    NSConnection * taskConnection = nil;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    while(taskConnection == nil){
        taskConnection = [NSConnection connectionWithRegisteredName:[NSString stringWithFormat:@"info.proxyplayer.movierenderer-%@", taskUUIDForDOServer, nil] host:nil];
    }
    
    // now that we have a valid connection...
    // movieProxy = [[taskConnection rootProxy] retain];
    [self setMovieProxy:[taskConnection rootProxy]];
    
    if(taskConnection == nil || movieProxy == nil){
        [moviePlayer stopProcess];
        moviePlayer = nil;
    }
    
    //[self movieProxy]
    [movieProxy setProtocolForProxy:@protocol(PCProxyProtocol)];
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
                
                if (USELAYER) {
                    [[self surfaceLayer] setSurfaceID: surfaceID];
                    [[self surfaceLayer] setNeedsDisplay];
                } else {
                    [view setSurfaceID: surfaceID];
                    [view setNeedsDisplay: YES];
                }
            
				numFrames++;
			}
		}
	}
	
	cmdStr	= [outComps lastObject];
	if (([cmdStr length] > 0) && ([cmdStr characterAtIndex: [cmdStr length] - 1] != '#')) {
//		NSLog(@"Storing %@ for later concat", cmdStr);
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
