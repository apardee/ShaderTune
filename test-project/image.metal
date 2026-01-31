#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 mouse;
    float2 resolution;
    float scale;
};

// Main shader - samples from BufferA
fragment float4 fragmentFunc(
    float4 position [[position]],
    constant Uniforms& uniforms [[buffer(0)]],
    texture2d<float> bufferA [[texture(0)]]
) {
    float2 uv = position.xy / uniforms.resolution;

    // Sample from BufferA
    constexpr sampler s(filter::linear);
    float4 bufferColor = bufferA.sample(s, uv);

    // Blend with a gradient
    float3 gradient = float3(uv.x, uv.y, 0.5 + 0.5 * sin(uniforms.time));
    float3 color = mix(gradient, bufferColor.rgb, 0.5);

    return float4(color, 1.0);
}
