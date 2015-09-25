//ShaderDemoAdd Fragment Shader

uniform sampler2D textureUnit0;
uniform sampler2D textureUnit1;
varying vec2 vTex;
uniform float myscale;

void main(void){
    
    vec4 base = texture2D(textureUnit0, vTex);
    vec4 blend = texture2D(textureUnit1, vTex);
    vec4 difference = abs(blend-base);
    
    difference.r = 	pow(difference.r, 1.0/myscale);
    difference.g = 	pow(difference.g, 1.0/myscale);
    difference.b = 	pow(difference.b, 1.0/myscale);
    difference.a = 	pow(difference.a, 1.0/myscale);
    
    gl_FragColor = difference;
}



//vec4 result = blend;// blend;
//vec4 result = base - blend;           //subtract
//vec4 result = max(blend,base);        //lighten
//vec4 result = blend * base;           //multiply
//vec4 result = abs(blend-base);          //difference
//vec4 result = base + blend - (2.0 * base * blend); //exclusion


