#include <flutter/runtime_effect.glsl>

precision mediump float;
//precision highp float;

// Inputs
uniform vec2 uResolution;
uniform float uTime;
uniform vec4 uColor;

// Outputs
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy/uResolution;

    //vec3 lightBlue = vec3(0.7, 0.9, 1.0);
    //vec3 color = mix(white, lightBlue, colorValue);

    float mult = st.x ;

    fragColor = vec4(1.0*mult, 0.0*mult, 0.0*mult, 1.0);
}