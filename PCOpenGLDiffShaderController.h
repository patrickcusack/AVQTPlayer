//
//  PCOpenGLDIffShaderController.h
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 7/2/15.
//  Copyright (c) 2015 Paolo Manna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

@interface PCOpenGLDiffShaderController : NSObject

- (void)useDualShaderWithMatrix:(GLfloat*)matrix;

@end
