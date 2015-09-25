//
//  IOSurfaceLayerView.h
//  IOSurfaceTest2
//
//  Created by Patrick Cusack on 5/7/15.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl.h>
#import <IOSurface/IOSurface.h>

@interface IOSurfaceLayer : CAOpenGLLayer{
    GLuint			_surfaceTexture;
    IOSurfaceRef	_surface;
    GLsizei			_texWidth;
    GLsizei			_texHeight;
    uint32_t		_seed;
    NSSize          _movieSize;
    
    IOSurfaceID     _surfaceID;
}

- (void)setMovieSize:(NSSize)size;
- (void)setSurfaceID: (IOSurfaceID)anID;

@end
