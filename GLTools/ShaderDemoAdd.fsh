//ShaderDemoAdd Fragment Shader

uniform sampler2D textureUnit0;
uniform sampler2D textureUnit1;
varying vec2 vTex;

void main(void){
    
    vec4 base = texture2D(textureUnit0, vTex);
    vec4 blend = texture2D(textureUnit1, vTex);

    gl_FragColor = blend;
}



//vec4 result = blend;// blend;
//vec4 result = base - blend;           //subtract
//vec4 result = max(blend,base);        //lighten
//vec4 result = blend * base;           //multiply
//vec4 result = abs(blend-base);          //difference
//vec4 result = base + blend - (2.0 * base * blend); //exclusion


