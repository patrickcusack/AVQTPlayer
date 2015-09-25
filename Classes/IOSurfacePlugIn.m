/*
 *  IOSurfacePlugIn.m
 *  IOSurfaceTest
 *
 *  Created by Paolo on 08/10/2009.
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

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */

#import "IOSurfacePlugIn.h"
#import <OpenGL/CGLIOSurface.h>
#import <OpenGL/CGLMacro.h>

// Define this to use a GL texture as image provider:
// the alternative is a safer (but slower) pixel buffer copy
#define USE_TEXTURE_PROVIDER

#define	kQCPlugIn_Name				@"IOSurfaceTest"
#define	kQCPlugIn_Description		@"IOSurfaceTest description"

@implementation IOSurfacePlugIn

@dynamic inputFileName, inputPlay, outputImage;

+ (NSDictionary*) attributes
{
	/*
	Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
	*/
	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSArray*) sortedPropertyPortKeys {
	return [NSArray arrayWithObjects: @"inputFileName", @"inputPlay", @"outputImage",nil];
}


+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	if ([key isEqualToString:@"inputFileName"])
		return [NSDictionary dictionaryWithObjectsAndKeys: @"Movie Path", QCPortAttributeNameKey, nil];
	
	if ([key isEqualToString:@"inputPlay"])
		return [NSDictionary dictionaryWithObjectsAndKeys: @"Play", QCPortAttributeNameKey, nil];
	
	
	if ([key isEqualToString:@"outputImage"])
		return [NSDictionary dictionaryWithObjectsAndKeys: @"Output Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/
	
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/
	
	return kQCPlugInTimeModeTimeBase;
}

- (id) init
{
	if(self = [super init]) {
		/*
		Allocate any permanent resource required by the plug-in.
		*/
	}
	
	return self;
}

- (void) finalize
{
	/*
	Release any non garbage collected resources created in -init.
	*/
	
	[super finalize];
}

- (void) dealloc
{
	/*
	Release any resources created in -init.
	*/
	if (_moviePlaying) {
		[moviePlayer autorelease];
	}
	
	[super dealloc];
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
				// Process the ID
				_surfaceID	= surfaceID;
				_frameReady	= YES;
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
	[inputRemainder autorelease];	inputRemainder	= nil;
}

@end

@implementation IOSurfacePlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/
	CGLContextObj	cgl_ctx	= [context CGLContextObj];
	GLfloat			projMatrix[16]	= {0};
	GLfloat			modelMatrix[16]	= {0};
	GLint			matrixMode;
	
	glGetIntegerv(GL_MATRIX_MODE, &matrixMode);
	glGetFloatv(GL_MODELVIEW_MATRIX, modelMatrix);
	glGetFloatv(GL_PROJECTION_MATRIX, projMatrix);
	
	NSLog(@"Matrix Mode: %@", (matrixMode == GL_MODELVIEW ? @"Model" : (matrixMode == GL_PROJECTION ? @"Projection" : @"Unknown")));
	NSLog(@"Projection:\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f",
		  projMatrix[0], projMatrix[1], projMatrix[2], projMatrix[3], projMatrix[4], projMatrix[5], projMatrix[6], projMatrix[7], 
		  projMatrix[8], projMatrix[9], projMatrix[10], projMatrix[11], projMatrix[12], projMatrix[13], projMatrix[14], projMatrix[15]);
	NSLog(@"Model:\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f\n%6.2f\t%6.2f\t%6.2f\t%6.2f",
		  modelMatrix[0], modelMatrix[1], modelMatrix[2], modelMatrix[3], modelMatrix[4], modelMatrix[5], modelMatrix[6], modelMatrix[7], 
		  modelMatrix[8], modelMatrix[9], modelMatrix[10], modelMatrix[11], modelMatrix[12], modelMatrix[13], modelMatrix[14], modelMatrix[15]);
	
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

static void TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* context)
{
	glDeleteTextures(1, &name);
}

static void imageBufferReleaseCallback (const void *address, void *context)
{
	free((void *)address);
}

- (void)_setupTaskWrapper
{
	NSString	*cliPath	= [[NSBundle bundleForClass: [self class]] pathForResource: @"IOSurfaceCLI" ofType: @""];
	NSArray		*args;
	
	if ([self.inputFileName length] > 1)
		args	= [NSArray arrayWithObjects: cliPath, @"-g", self.inputFileName, nil];
	else
		args	= [NSArray arrayWithObjects: cliPath, @"-g", @"-d", nil];

	moviePlayer	= [[TaskWrapper alloc] initWithController: self arguments: args userInfo: nil];
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	if (_frameReady) {
		CGLContextObj	cgl_ctx		= [context CGLContextObj];
		IOSurfaceRef	surface		= IOSurfaceLookup(_surfaceID);
		
		if (surface) {
			size_t			texWidth;
			size_t			texHeight;
			size_t			rowBytes;
#if __BIG_ENDIAN__
			NSString		*bufferFormat	= QCPlugInPixelFormatARGB8;
#else
			NSString		*bufferFormat	= QCPlugInPixelFormatBGRA8;
#endif
			
			texWidth	= IOSurfaceGetWidth(surface);
			texHeight	= IOSurfaceGetHeight(surface);
			rowBytes	= IOSurfaceGetBytesPerRow(surface);
			
			if (_moviePlaying && (texWidth > 1) && (texHeight > 1)) {
#ifdef	USE_TEXTURE_PROVIDER
				GLuint			surfaceTexture;
				
				CGLLockContext(cgl_ctx);
				
				glPushAttrib(GL_ALL_ATTRIB_BITS);
				glEnable(GL_TEXTURE_RECTANGLE_ARB);
				glGenTextures(1, &surfaceTexture);
				glBindTexture(GL_TEXTURE_RECTANGLE_ARB, surfaceTexture);
				CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA8,
									   texWidth, texHeight,
									   GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, surface, 0);
				glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
				glDisable(GL_TEXTURE_RECTANGLE_ARB);
				glPopAttrib();
				
				CGLUnlockContext(cgl_ctx);
				
				self.outputImage	= [context outputImageProviderFromTextureWithPixelFormat: bufferFormat
																			   pixelsWide: texWidth
																			   pixelsHigh: texHeight
																					 name: surfaceTexture
																				  flipped: YES
																		  releaseCallback: TextureReleaseCallback
																		   releaseContext: NULL
																			   colorSpace: [context colorSpace]
																		 shouldColorMatch: YES];
#else
				size_t	bufSize			= texHeight * rowBytes;
				void	*baseAddress	= valloc(bufSize);
				
				memcpy(baseAddress, IOSurfaceGetBaseAddress(surface), bufSize);
				
				self.outputImage	= [context outputImageProviderFromBufferWithPixelFormat: bufferFormat
																			  pixelsWide: texWidth
																			  pixelsHigh: texHeight
																			 baseAddress: baseAddress
																			 bytesPerRow: rowBytes
																		 releaseCallback: imageBufferReleaseCallback
																		  releaseContext: NULL
																			  colorSpace: [context colorSpace]
																		shouldColorMatch: YES];
#endif
			}
			CFRelease(surface);
		}
		
		_frameReady	= NO;
	}
	
	if ([self didValueForInputKeyChange: @"inputFileName"]) {
		if (_moviePlaying) {
			[moviePlayer autorelease];	moviePlayer	= nil;
		}
		
		[self _setupTaskWrapper];
		
		if (moviePlayer && self.inputPlay)
			[moviePlayer startProcess];
	}
	
	if ([self didValueForInputKeyChange: @"inputPlay"]) {
		if (moviePlayer && _moviePlaying && (!self.inputPlay)) {
			[moviePlayer autorelease];	moviePlayer	= nil;
		}
		
		if ((!_moviePlaying) && self.inputPlay) {
			if (!moviePlayer)
				[self _setupTaskWrapper];
			[moviePlayer startProcess];
		}
	}
	
	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
}

@end
