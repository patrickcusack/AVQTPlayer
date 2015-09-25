//
// ShaderHelpers.h
//

#include <OpenGL/gltypes.h>

void checkGlError(const char* op);
GLuint loadShader(GLenum shaderType, const char* pSource);
GLuint createProgramFromFiles(const char *shaderName);
GLuint createProgram(const char* pVertexSource,
                     const char* pFragmentSource);

