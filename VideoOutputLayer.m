//
//  VideoOutputLayer.m
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/8/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import "VideoOutputLayer.h"


#define ADVANCE_INTERVAL_IN_SECONDS 0.1
#define ALTORTHO 1

@implementation VideoOutputLayerPixelType : NSObject
@synthesize pixelBufferType;
@synthesize internalFormat;
@synthesize format;
@synthesize type;
@synthesize byteCount;

+ (VideoOutputLayerPixelType*)TypeBGRA32{
    VideoOutputLayerPixelType * pixelType = [[[VideoOutputLayerPixelType alloc] init] autorelease];
    [pixelType setPixelBufferType:kCVPixelFormatType_32BGRA];
    [pixelType setInternalFormat:GL_RGBA];
    [pixelType setFormat:GL_BGRA];
    [pixelType setType:GL_UNSIGNED_BYTE];
    [pixelType setByteCount:4];
    return pixelType;
}

+ (VideoOutputLayerPixelType*)TypeRGB24{
    VideoOutputLayerPixelType * pixelType = [[[VideoOutputLayerPixelType alloc] init] autorelease];
    [pixelType setPixelBufferType:kCVPixelFormatType_24RGB];
    [pixelType setInternalFormat:GL_RGB];
    [pixelType setFormat:GL_RGB];
    [pixelType setType:GL_UNSIGNED_BYTE];
    [pixelType setByteCount:3];
    return pixelType;
}

+ (VideoOutputLayerPixelType*)Type422YpCbCr8{
    VideoOutputLayerPixelType * pixelType = [[[VideoOutputLayerPixelType alloc] init] autorelease];
    [pixelType setPixelBufferType:kCVPixelFormatType_422YpCbCr8];
    [pixelType setInternalFormat:GL_RGB8];
    [pixelType setFormat:GL_YCBCR_422_APPLE];
    [pixelType setType:GL_UNSIGNED_SHORT_8_8_APPLE];
    [pixelType setByteCount:2];
    return pixelType;
}

@end


@interface VideoOutputLayer (){
    AVPlayerItemVideoOutput * _videoOutput;
    uint64_t _lastHostTime;
    dispatch_queue_t _queue;

}

@end

@implementation VideoOutputLayer
@synthesize currentPlayer;
@synthesize videoTapDelegate;
@synthesize forceUpdate;
@synthesize pixelType;

- (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute	mAttrs []	= {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize,		(NSOpenGLPixelFormatAttribute)32,
        NSOpenGLPFAAlphaSize,		(NSOpenGLPixelFormatAttribute)8,
        NSOpenGLPFADepthSize,		(NSOpenGLPixelFormatAttribute)24,
        (NSOpenGLPixelFormatAttribute) 0
    };
    
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes: mAttrs] autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setAsynchronous:YES];
        [self setContentsGravity:kCAGravityResizeAspect];
        
        //This must be opaque
        CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 1);
        [self setBackgroundColor:black];
        CFRelease(black);
            
        _queue = dispatch_queue_create(NULL, NULL);
        
        [self setPixelType:[VideoOutputLayerPixelType TypeBGRA32]];
        
        NSDictionary *options = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:[[self pixelType] pixelBufferType]],
                                  (id)kCVPixelBufferOpenGLCompatibilityKey:[NSNumber numberWithBool:YES]};
        
        _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:options];
        if (_videoOutput){
            [_videoOutput setDelegate:self queue:_queue];
            [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ADVANCE_INTERVAL_IN_SECONDS];
        }
        
        [self setContentsScale:2.0];
        _currentPixelBufferRef = NULL;
    }
    return self;
}

- (void)dealloc{
    [self setCurrentPlayer:nil];
    [self setPixelType:nil];
    
    if (_videoOutput) {
        [_videoOutput release];
        _videoOutput = nil;
    }
    
    if (_surfaceTexture) {
        glDeleteTextures(1, &_surfaceTexture);
    }
    
    [self setVideoTapDelegate:nil];
    
//    [super dealloc];
}


-(CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask{
    NSOpenGLPixelFormatAttribute	mAttrs []	= {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize,		(NSOpenGLPixelFormatAttribute)32,
        NSOpenGLPFAAlphaSize,		(NSOpenGLPixelFormatAttribute)8,
        NSOpenGLPFADepthSize,		(NSOpenGLPixelFormatAttribute)24,
        (NSOpenGLPixelFormatAttribute) 0
    };
    
    NSOpenGLPixelFormat * pxlFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: mAttrs];
    [pxlFormat autorelease];
    
    return [pxlFormat CGLPixelFormatObj];
}

- (void)setMovieSize:(NSSize)size{
    _movieSize = size;
    
    if ([self videoTapDelegate]) {
        [[self videoTapDelegate] setMovieSize:size];
    }
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx
                pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t
                displayTime:(const CVTimeStamp *)ts{
    
    CGLSetCurrentContext(ctx);
    
    if (!_surfaceTexture) {
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glGenTextures(1, &_surfaceTexture);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
    }
    
    CMTime vTime = [_videoOutput itemTimeForHostTime:CACurrentMediaTime()];
    
    if ([_videoOutput hasNewPixelBufferForItemTime:vTime] || [self forceUpdate] == YES) {
        
        if (_currentPixelBufferRef) {
            CVPixelBufferRelease(_currentPixelBufferRef);
        }
        
        _currentPixelBufferRef = [_videoOutput copyPixelBufferForItemTime:vTime itemTimeForDisplay:NULL];
        
        if ([self videoTapDelegate]) {
            
            CMTime currentPlayerItemTime = CMTimeConvertScale(vTime, [[self currentPlayer] naturalTimeScale], kCMTimeRoundingMethod_QuickTime);
            NSUInteger currentFrame = currentPlayerItemTime.value/[[self currentPlayer] frameSize];
            
            PCVideoTapStruct tapStruct;
            
            tapStruct.buffer = _currentPixelBufferRef;
            tapStruct.internalFormat = [[self pixelType] internalFormat];
            tapStruct.format = [[self pixelType] format];
            tapStruct.type = [[self pixelType] type];
            tapStruct.numberOfBytes = [[self pixelType] byteCount];
            tapStruct.currentFrame = currentFrame;
            
            [[self videoTapDelegate] addPixelBuffer:tapStruct fromObject:self];
        }
        
        [self setForceUpdate:NO];
        
        return YES;
    }
    return NO;
}

- (void)attachPixelBufferToTexture:(CVPixelBufferRef)bufferRef inContext:(CGLContextObj)context{
    
    CGLSetCurrentContext(context);

    if (bufferRef != nil) {

        CVPixelBufferLockBaseAddress(bufferRef, 0);
        
        _texWidth	= (GLsizei)CVPixelBufferGetWidth(bufferRef);
        _texHeight	= (GLsizei)CVPixelBufferGetHeight(bufferRef);
        
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _surfaceTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        GLubyte * data = (GLubyte *)CVPixelBufferGetBaseAddress(bufferRef);
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, [[self pixelType] internalFormat], _texWidth, _texHeight, 0, [[self pixelType] format], [[self pixelType] type], data);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
                
//        FILE * pFile = fopen("test", "wb");
//        if (pFile) {
//            fwrite(data, sizeof(uint8_t), _texWidth * _texHeight * [[self pixelType] byteCount], pFile);
//            fclose(pFile);
//        }
        
        CVPixelBufferUnlockBaseAddress(bufferRef, 0);
        
    }
}

-(void)drawInCGLContext:(CGLContextObj)glContext pixelFormat:(CGLPixelFormatObj)pixelFormat forLayerTime:(CFTimeInterval)timeInterval displayTime:(const CVTimeStamp *)timeStamp{
    
    // Set the current context to the one given to us.
    CGLSetCurrentContext(glContext);
    
    [self attachPixelBufferToTexture:_currentPixelBufferRef inContext:glContext];
    
    CGRect backingBounds = [self bounds];
    backingBounds.size.width *= [self contentsScale];
    backingBounds.size.height *= [self contentsScale];
    
    glViewport(0, 0, backingBounds.size.width, backingBounds.size.height);
    
    float scaleX = backingBounds.size.width / _movieSize.width;
    float scaleY = backingBounds.size.height / _movieSize.height;
    float scaleN = 0.0;
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    if(scaleX > scaleY){
        scaleN = scaleX / scaleY;
        glOrtho(-1 * scaleN, 1 * scaleN, -1 , 1, -20., 20.);
    } else {
        scaleN = scaleY / scaleX;
        glOrtho(-1, 1, -1 * scaleN, 1* scaleN, -20., 20.);
    }
    
    //Clear background
    //    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if(_currentPixelBufferRef){
        GLfloat		texMatrix[16]	= {0};
        GLint		saveMatrixMode;
        
        // Reverses and normalizes the texture
        texMatrix[0]	= (GLfloat)_texWidth;
        texMatrix[5]	= -(GLfloat)_texHeight;
        texMatrix[10]	= 1.0;
        texMatrix[13]	= (GLfloat)_texHeight;
        texMatrix[15]	= 1.0;
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glLoadMatrixf(texMatrix);
        glMatrixMode(saveMatrixMode);
        
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _surfaceTexture);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
        
    } else {
        glColor4f(0.4, 0.4, 0.4, 0.4);
    }
    
    //Draw textured quad
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glEnd();
    
    //Restore texturing settings
    
    if (_currentPixelBufferRef) {
        GLint		saveMatrixMode;
        
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPopMatrix();
        glMatrixMode(saveMatrixMode);
    }
    
    // Call super to finalize the drawing. By default all it does is call glFlush().
    [super drawInCGLContext:glContext pixelFormat:pixelFormat forLayerTime:timeInterval displayTime:timeStamp];
}

- (void)addPlayer:(PCMoviePlayer*)nPlayer{
    [self removeCurrentPlayer:[self currentPlayer]];
    [self setCurrentPlayer:nPlayer];
    [[[self currentPlayer] playerItem] addOutput:_videoOutput];
    [self setMovieSize:[nPlayer sizeOfVideoTrack]];
    [self setNeedsDisplay];
}

- (void)removeCurrentPlayer:(PCMoviePlayer*)nPLayer{
    [[[self currentPlayer] playerItem] removeOutput:_videoOutput];
    [self setCurrentPlayer:nil];
}

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    _lastHostTime = CVGetCurrentHostTime();
}




@end