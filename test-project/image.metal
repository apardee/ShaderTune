// Uniforms are provided automatically by ShaderTune
// struct Uniforms {
//     float time;
//     float2 mouse;
//     float2 resolution;
//     float scale;
// };

// Main shader - samples from BufferA
fragment float4 fragmentFunc(
    float4 position [[position]],
    constant Uniforms& uniforms [[buffer(0)]],
    texture2d<float> bufferA [[texture(0)]]
) {
   return bufferA.so
}
