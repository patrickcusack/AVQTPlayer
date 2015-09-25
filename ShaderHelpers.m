//
// ShaderHelpers.mm
//
// Most of this code is reworked from Apple's OpenGL Game
// template that ships with Xcode 4. Feel free to use this
// anywhere without attribution, for if you generated that
// project from Xcode it would put your name on its
// copyright.
//

#include "ShaderHelpers.h"
#include <Foundation/Foundation.h>
#include <OpenGL/gl.h>

#pragma mark - Loading shader files from bundle

GLuint createProgramFromFiles(const char *shaderName)
{
    NSString *baseShaderName = [NSString stringWithCString:shaderName encoding:NSUTF8StringEncoding];
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *vshPath = [bundle pathForResource:baseShaderName ofType:@"vsh"];
    NSError *err = nil;
    NSString *vshContents = [NSString stringWithContentsOfFile:vshPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&err];
    
    err = nil;
    NSString *fshPath = [bundle pathForResource:baseShaderName ofType:@"fsh"];
    NSString *fshContents = [NSString stringWithContentsOfFile:fshPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&err];

    return createProgram([vshContents UTF8String],
                         [fshContents UTF8String]);
}

const char *shaderPath(const char *shaderName)
{
    NSString *shaderNameStr = [NSString stringWithCString:shaderName encoding:NSUTF8StringEncoding];
    
    NSString *baseShaderName = [shaderNameStr stringByDeletingPathExtension];
    NSString *shaderExtension = [shaderNameStr pathExtension];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:baseShaderName ofType:shaderExtension];
    
    const char *cPath = [path UTF8String];
    
    NSLog(@"Path for %@", path);
    
    return cPath;
}

#pragma mark - OpenGL diagnostics

static void printGLString(const char *name, GLenum s) {
    const char *v = (const char *) glGetString(s);
    NSLog(@"GL %s = %s\n", name, v);
}

void checkGlError(const char* op)
{
    for (GLint error = glGetError(); error; error
         = glGetError()) {
        NSLog(@"after %s() glError (0x%x)\n", op, error);
    }
}

#pragma mark - OpenGLES Shader loading

GLuint loadShader(GLenum shaderType, const char* pSource)
{
    GLuint shader = glCreateShader(shaderType);
    if (shader) {
        glShaderSource(shader, 1, &pSource, NULL);
        glCompileShader(shader);
        GLint compiled = 0;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen) {
                char* buf = (char*) malloc(infoLen);
                if (buf) {
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    NSLog(@"Could not compile shader %d:\n%s\n",
                          shaderType, buf);
                    free(buf);
                }
                glDeleteShader(shader);
                shader = 0;
            }
        }
    }
    return shader;
}

GLuint createProgram(
    const char* pVertexSource,
    const char* pFragmentSource)
{
    GLuint vertexShader = loadShader(GL_VERTEX_SHADER, pVertexSource);
    if (!vertexShader) {
        return 0;
    }
    
    GLuint pixelShader = loadShader(GL_FRAGMENT_SHADER, pFragmentSource);
    if (!pixelShader) {
        return 0;
    }
    
    GLuint program = glCreateProgram();
    if (program) {
        glAttachShader(program, vertexShader);
        checkGlError("glAttachShader");
        glAttachShader(program, pixelShader);
        checkGlError("glAttachShader");
        glLinkProgram(program);
        GLint linkStatus = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            GLint bufLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufLength);
            if (bufLength) {
                char* buf = (char*) malloc(bufLength);
                if (buf) {
                    glGetProgramInfoLog(program, bufLength, NULL, buf);
                    NSLog(@"Could not link program:\n%s\n", buf);
                    free(buf);
                }
            }
            glDeleteProgram(program);
            program = 0;
        }
    }
    return program;
}

