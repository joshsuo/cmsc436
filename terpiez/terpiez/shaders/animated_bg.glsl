#include <flutter/runtime_effect.glsl>

precision mediump float;

// Inputs
uniform vec2 uResolution;
uniform float uTime;

// Outputs
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy/uResolution;
    float denom = 2.0;
    float red = st.x * uTime / denom;
    float green = st.y * uTime / denom;
    float blue = 1.0 - (st.x - st.y) * uTime / denom;
    fragColor = vec4(red, green, blue, 1.0);
}