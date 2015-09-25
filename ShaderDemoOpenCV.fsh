//ShaderDemoAdd Fragment Shader

uniform sampler2D textureUnit0;
varying vec2 vTex;

void main(void){
    vec4 base = texture2D(textureUnit0, vTex);
    gl_FragColor = base;
}

