#include <flutter/runtime_effect.glsl>

precision mediump float;
//precision highp float;

// Inputs
uniform vec2 uResolution;
uniform float uTime;

// Outputs
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy/uResolution;

    float scale = 12.0;
    vec2 grid = floor(st * scale);

    float checker = mod(grid.x + grid.y, 2.0);

    float invert = mod(floor(uTime * 0.5), 2.0);

    float colorValue = abs(checker - invert);

    //vec3 red = vec3(1.0, 0.0, 0.0);
    //vec3 green = vec3(0.0, 1.0, 0.0);
    vec3 white = vec3(1.0, 1.0, 1.0);
    vec3 lightBlue = vec3(0.7, 0.9, 1.0);

    //vec3 color = mix(red, green, colorValue);
    vec3 color = mix(white, lightBlue, colorValue);

    fragColor = vec4(color, 1.0);

}