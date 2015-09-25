//
//  VideoOutputLayer.h
//  AVFoundationMoviePlayer
//
//  Created by Patrick Cusack on 5/8/15.
//  Copyright (c) 2015 Patrick Cusack. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <IOSurface/IOSurface.h>
#import <OpenGL/gl.h>
#import "PCMoviePlayer.h"
#import "PCVideoTapDelegateProtocol.h"

@interface VideoOutputLayerPixelType : NSObject{
    OSType pixelBufferType;
    GLint internalFormat;
    GLint format;
    GLint type;
    OSType pixelType;
    uint8_t byteCount;
}

+ (VideoOutputLayerPixelType*)TypeBGRA32;
+ (VideoOutputLayerPixelType*)Type422YpCbCr8;

@property(nonatomic, assign,readwrite) OSType pixelBufferType;
@property(nonatomic, assign,readwrite) GLint internalFormat;
@property(nonatomic, assign,readwrite) GLint format;
@property(nonatomic, assign,readwrite) GLint type;
@property(nonatomic, assign,readwrite) uint8_t byteCount;

@end

@interface VideoOutputLayer : CAOpenGLLayer <AVPlayerItemOutputPullDelegate> {
    
    PCMoviePlayer * currentPlayer;
    CGDirectDisplayID   _mainViewDisplayID;
    
    GLuint              _surfaceTexture;
    CVPixelBufferRef    _currentPixelBufferRef;
    GLsizei             _texWidth;
    GLsizei             _texHeight;
    uint32_t            _seed;
    NSSize              _movieSize;
    
    VideoOutputLayerPixelType * pixelType;
    
    id <PCVideoTapDelegateProtocol> videoTapDelegate;
    
    BOOL                forceUpdate;
}

- (void)addPlayer:(PCMoviePlayer*)nPLayer;
- (void)removeCurrentPlayer:(PCMoviePlayer*)nPLayer;

@property (nonatomic, retain, readwrite) PCMoviePlayer * currentPlayer;
@property (nonatomic, retain, readwrite) VideoOutputLayerPixelType * pixelType;
@property (nonatomic, assign, readwrite) BOOL forceUpdate;
@property (nonatomic, assign, readwrite) id <PCVideoTapDelegateProtocol> videoTapDelegate;

@end
