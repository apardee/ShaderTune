// Uniforms are provided automatically by ShaderTune
// struct Uniforms {
//     float time;
//     float2 mouse;
//     float2 resolution;
//     float scale;
// };

// BufferA - accumulating feedback effect
fragment float4 fragmentFunc(
    float4 position [[position]],
    constant Uniforms& uniforms [[buffer(0)]],
    texture2d<float> previousFrame [[texture(7)]]  // Feedback from previous frame
) {
    return float4(1.0, 1.0, 1.0, 1.0);
}
