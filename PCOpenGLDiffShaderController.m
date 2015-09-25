//
//  PCOpenGLDIffShaderController.m
//  IOSurfaceTest_Renamed
//
//  Created by Patrick Cusack on 7/2/15.
//  Copyright (c) 2015 Paolo Manna. All rights reserved.
//

#import "PCOpenGLDiffShaderController.h"
#import "ShaderHelpers.h"
#import <OpenGL/gl3.h>

@interface PCOpenGLDiffShaderController(){
    GLuint shaderProgram;
}

@end

@implementation PCOpenGLDiffShaderController

- (instancetype)init
{
    self = [super init];
    if (self) {
        shaderProgram = createProgramFromFiles("ShaderDemoAdd");
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
}

- (void)useDualShaderWithMatrix:(GLfloat*)matrix{
    
    glUseProgram(shaderProgram);
    
    GLint iTransform, iTextureUnit0, iTextureUnit1;
    
    iTransform = glGetUniformLocation(shaderProgram, "mvpMatrix");
    glUniformMatrix4fv(iTransform, 1, GL_FALSE, matrix);
    
    iTextureUnit0 = glGetUniformLocation(shaderProgram, "textureUnit0");
    iTextureUnit1 = glGetUniformLocation(shaderProgram, "textureUnit1");
    
    glUniform1i(iTextureUnit0, 0);
    glUniform1i(iTextureUnit1, 1);
    
}

@end
