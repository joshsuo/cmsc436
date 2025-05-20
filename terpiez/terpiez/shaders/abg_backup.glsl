#include <flutter/runtime_effect.glsl>

//precision mediump float;
precision highp float;

// Inputs
uniform vec2 uResolution;
uniform float uTime;

// Outputs
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy/uResolution;
    //float denom = 2.0;
    //float red = st.x * uTime / denom;
    //float green = st.y * uTime / denom;
    //float blue = 1.0 - (st.x - st.y) * uTime / denom;
    //fragColor = vec4(red, green, blue, 1.0);

    float scale = 50.0;
    vec2 grid = floor(st * scale);

    float checker = mod(grid.x + grid.y, 2.0);

    float invert = mod(floor(uTime * 0.5), 2.0);

    float colorValue = abs(checker - invert);

    fragColor = vec4(vec3(colorValue), 1.0);


    //vec2 st = FlutterFragCoord().xy/uResolution.xy;

    //st.x *= uResolution.x / uResolution.y;

    //vec3 color = vec(0.);
    //color = vec3(st.x, st.y, abs(sin(uTime)));
}