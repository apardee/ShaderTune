// Uniforms are provided automatically by ShaderTune
// struct Uniforms {
//     float time;
//     float2 mouse;
//     float2 resolution;
//     float scale;
// };

fragment float4 fragmentFunc(
    float4 position [[position]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    return float4(0.0, 1.0, 0.0, 1.0);
}