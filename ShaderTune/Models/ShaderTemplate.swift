import Foundation

struct ShaderTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: TemplateCategory
    let source: String

    enum TemplateCategory: String, CaseIterable {
        case fragment = "Fragment Shaders"
        case vertex = "Vertex Shaders"
        case compute = "Compute Kernels"
        case complete = "Complete Pipelines"
    }
}

extension ShaderTemplate {
    static let allTemplates: [ShaderTemplate] = [
        // Fragment Shaders
        .basicFragment,
        .gradientFragment,
        .textureFragment,
        .proceduralNoiseFragment,

        // Vertex Shaders
        .passthroughVertex,
        .transformVertex,

        // Compute Kernels
        .imageProcessingKernel,
        .gaussianBlurKernel,

        // Complete Pipelines
        .basicPipeline,
        .texturedPipeline,
    ]

    // MARK: - Fragment Shaders

    static let basicFragment = ShaderTemplate(
        name: "Basic Fragment Shader",
        description: "Simple solid color fragment shader",
        category: .fragment,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
            return float4(1.0, 0.5, 0.2, 1.0);
        }
        """
    )

    static let gradientFragment = ShaderTemplate(
        name: "Gradient Fragment Shader",
        description: "Animated color gradient effect",
        category: .fragment,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                       constant float &time [[buffer(0)]]) {
            float2 uv = in.texCoord;

            // Create animated color gradient
            float r = 0.5 + 0.5 * sin(uv.x * 3.0 + time);
            float g = 0.5 + 0.5 * sin(uv.y * 3.0 + time * 0.7);
            float b = 0.5 + 0.5 * cos(length(uv - 0.5) * 5.0 - time);

            return float4(r, g, b, 1.0);
        }
        """
    )

    static let textureFragment = ShaderTemplate(
        name: "Texture Fragment Shader",
        description: "Sample and display a texture",
        category: .fragment,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                       texture2d<float> colorTexture [[texture(0)]]) {
            constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
            float4 color = colorTexture.sample(textureSampler, in.texCoord);
            return color;
        }
        """
    )

    static let proceduralNoiseFragment = ShaderTemplate(
        name: "Procedural Noise",
        description: "Generate procedural noise pattern",
        category: .fragment,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        // Simple hash function for noise
        float hash(float2 p) {
            p = fract(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return fract(p.x * p.y);
        }

        // Value noise
        float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            f = f * f * (3.0 - 2.0 * f);

            float a = hash(i);
            float b = hash(i + float2(1.0, 0.0));
            float c = hash(i + float2(0.0, 1.0));
            float d = hash(i + float2(1.0, 1.0));

            return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
        }

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                       constant float &time [[buffer(0)]]) {
            float2 uv = in.texCoord * 8.0;
            float n = noise(uv + time);
            return float4(n, n, n, 1.0);
        }
        """
    )

    // MARK: - Vertex Shaders

    static let passthroughVertex = ShaderTemplate(
        name: "Passthrough Vertex Shader",
        description: "Simple vertex shader that passes data through",
        category: .vertex,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
            float2 texCoord [[attribute(1)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
            VertexOut out;
            out.position = in.position;
            out.texCoord = in.texCoord;
            return out;
        }
        """
    )

    static let transformVertex = ShaderTemplate(
        name: "Transform Vertex Shader",
        description: "Vertex shader with model-view-projection matrices",
        category: .vertex,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
            float3 normal [[attribute(1)]];
            float2 texCoord [[attribute(2)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float3 normal;
            float2 texCoord;
        };

        struct Uniforms {
            float4x4 modelMatrix;
            float4x4 viewMatrix;
            float4x4 projectionMatrix;
        };

        vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                                      constant Uniforms &uniforms [[buffer(1)]]) {
            VertexOut out;

            float4x4 mvp = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix;
            out.position = mvp * in.position;

            float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz,
                                            uniforms.modelMatrix[1].xyz,
                                            uniforms.modelMatrix[2].xyz);
            out.normal = normalMatrix * in.normal;
            out.texCoord = in.texCoord;

            return out;
        }
        """
    )

    // MARK: - Compute Kernels

    static let imageProcessingKernel = ShaderTemplate(
        name: "Image Processing Kernel",
        description: "Basic compute kernel for image processing",
        category: .compute,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        kernel void imageProcessing(
            texture2d<float, access::read> inTexture [[texture(0)]],
            texture2d<float, access::write> outTexture [[texture(1)]],
            uint2 gid [[thread_position_in_grid]]
        ) {
            // Read input pixel
            float4 color = inTexture.read(gid);

            // Apply grayscale effect
            float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
            float4 result = float4(gray, gray, gray, color.a);

            // Write output pixel
            outTexture.write(result, gid);
        }
        """
    )

    static let gaussianBlurKernel = ShaderTemplate(
        name: "Gaussian Blur Kernel",
        description: "Compute kernel for Gaussian blur effect",
        category: .compute,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        kernel void gaussianBlur(
            texture2d<float, access::read> inTexture [[texture(0)]],
            texture2d<float, access::write> outTexture [[texture(1)]],
            uint2 gid [[thread_position_in_grid]]
        ) {
            // 3x3 Gaussian kernel
            const float kernel[3][3] = {
                {1.0/16.0, 2.0/16.0, 1.0/16.0},
                {2.0/16.0, 4.0/16.0, 2.0/16.0},
                {1.0/16.0, 2.0/16.0, 1.0/16.0}
            };

            float4 color = float4(0.0);

            // Apply convolution
            for (int y = -1; y <= 1; y++) {
                for (int x = -1; x <= 1; x++) {
                    uint2 coord = uint2(int2(gid) + int2(x, y));
                    color += inTexture.read(coord) * kernel[y + 1][x + 1];
                }
            }

            outTexture.write(color, gid);
        }
        """
    )

    // MARK: - Complete Pipelines

    static let basicPipeline = ShaderTemplate(
        name: "Basic Render Pipeline",
        description: "Complete vertex + fragment shader pipeline",
        category: .complete,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
            float2 texCoord [[attribute(1)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        // Vertex Shader
        vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
            VertexOut out;
            out.position = in.position;
            out.texCoord = in.texCoord;
            return out;
        }

        // Fragment Shader
        fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
            return float4(in.texCoord, 0.5, 1.0);
        }
        """
    )

    static let texturedPipeline = ShaderTemplate(
        name: "Textured Render Pipeline",
        description: "Complete pipeline with texture sampling",
        category: .complete,
        source: """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
            float2 texCoord [[attribute(1)]];
        };

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        // Vertex Shader
        vertex VertexOut vertexShader(VertexIn in [[stage_in]]) {
            VertexOut out;
            out.position = in.position;
            out.texCoord = in.texCoord;
            return out;
        }

        // Fragment Shader
        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                       texture2d<float> colorTexture [[texture(0)]]) {
            constexpr sampler textureSampler(
                mag_filter::linear,
                min_filter::linear,
                address::repeat
            );

            float4 color = colorTexture.sample(textureSampler, in.texCoord);
            return color;
        }
        """
    )
}
