#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float time;
    float2 mouse;
    float2 resolution;
    float scale;
};

// BufferA - accumulating feedback effect
fragment float4 fragmentFunc(
    float4 position [[position]],
    constant Uniforms& uniforms [[buffer(0)]],
    texture2d<float> previousFrame [[texture(7)]]  // Feedback from previous frame
) {
    float2 uv = position.xy / uniforms.resolution;

    // Sample previous frame with slight offset for trail effect
    constexpr sampler s(filter::linear);
    float2 offset = float2(0.001 * sin(uniforms.time), 0.001 * cos(uniforms.time));
    float4 previous = previousFrame.sample(s, uv + offset);

    // Fade the previous frame
    float4 faded = previous * 0.98;

    // Add new content based on mouse position
    float2 mouseUV = uniforms.mouse / uniforms.resolution;
    float dist = distance(uv, mouseUV);
    float circle = smoothstep(0.05, 0.0, dist);

    // Animated color based on time
    float3 newColor = float3(
        0.5 + 0.5 * sin(uniforms.time),
        0.5 + 0.5 * sin(uniforms.time + 2.094),
        0.5 + 0.5 * sin(uniforms.time + 4.189)
    );

    // Combine faded previous with new content
    float3 color = faded.rgb + newColor * circle;

    return float4(color, 1.0);
}
