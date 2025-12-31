import Foundation

/// Comprehensive database of Metal Shading Language keywords, types, and functions for code completion
struct MetalKeywordDatabase {

    // MARK: - Completion Items

    static let allCompletions: [CompletionItem] = {
        return keywords + types + builtInFunctions + attributes
    }()

    // MARK: - Keywords

    static let keywords: [CompletionItem] = [
        // Function qualifiers
        CompletionItem(text: "kernel", kind: .keyword, description: "Compute kernel function qualifier"),
        CompletionItem(text: "vertex", kind: .keyword, description: "Vertex shader function qualifier"),
        CompletionItem(text: "fragment", kind: .keyword, description: "Fragment shader function qualifier"),

        // Address space qualifiers
        CompletionItem(text: "constant", kind: .keyword, description: "Constant address space qualifier"),
        CompletionItem(text: "device", kind: .keyword, description: "Device address space qualifier"),
        CompletionItem(text: "threadgroup", kind: .keyword, description: "Threadgroup address space qualifier"),
        CompletionItem(text: "threadgroup_imageblock", kind: .keyword, description: "Threadgroup imageblock address space"),

        // Type qualifiers
        CompletionItem(text: "const", kind: .keyword, description: "Constant type qualifier"),
        CompletionItem(text: "constexpr", kind: .keyword, description: "Constant expression"),
        CompletionItem(text: "static", kind: .keyword, description: "Static storage qualifier"),
        CompletionItem(text: "volatile", kind: .keyword, description: "Volatile type qualifier"),

        // Control flow
        CompletionItem(text: "if", kind: .keyword, description: "Conditional statement"),
        CompletionItem(text: "else", kind: .keyword, description: "Alternative conditional branch"),
        CompletionItem(text: "switch", kind: .keyword, description: "Switch statement"),
        CompletionItem(text: "case", kind: .keyword, description: "Case label"),
        CompletionItem(text: "default", kind: .keyword, description: "Default case label"),
        CompletionItem(text: "for", kind: .keyword, description: "For loop"),
        CompletionItem(text: "while", kind: .keyword, description: "While loop"),
        CompletionItem(text: "do", kind: .keyword, description: "Do-while loop"),
        CompletionItem(text: "break", kind: .keyword, description: "Break statement"),
        CompletionItem(text: "continue", kind: .keyword, description: "Continue statement"),
        CompletionItem(text: "return", kind: .keyword, description: "Return statement"),
        CompletionItem(text: "discard_fragment", kind: .keyword, description: "Discard current fragment"),

        // Namespace
        CompletionItem(text: "namespace", kind: .keyword, description: "Namespace declaration"),
        CompletionItem(text: "using", kind: .keyword, description: "Using directive"),

        // Other
        CompletionItem(text: "struct", kind: .keyword, description: "Structure type"),
        CompletionItem(text: "enum", kind: .keyword, description: "Enumeration type"),
        CompletionItem(text: "typedef", kind: .keyword, description: "Type definition"),
    ]

    // MARK: - Types

    static let types: [CompletionItem] = [
        // Scalar types
        CompletionItem(text: "void", kind: .type, description: "Void type"),
        CompletionItem(text: "bool", kind: .type, description: "Boolean type"),
        CompletionItem(text: "char", kind: .type, description: "8-bit signed integer"),
        CompletionItem(text: "uchar", kind: .type, description: "8-bit unsigned integer"),
        CompletionItem(text: "short", kind: .type, description: "16-bit signed integer"),
        CompletionItem(text: "ushort", kind: .type, description: "16-bit unsigned integer"),
        CompletionItem(text: "int", kind: .type, description: "32-bit signed integer"),
        CompletionItem(text: "uint", kind: .type, description: "32-bit unsigned integer"),
        CompletionItem(text: "half", kind: .type, description: "16-bit floating point"),
        CompletionItem(text: "float", kind: .type, description: "32-bit floating point"),

        // Vector types (2 components)
        CompletionItem(text: "bool2", kind: .type, description: "2-component boolean vector"),
        CompletionItem(text: "char2", kind: .type, description: "2-component char vector"),
        CompletionItem(text: "uchar2", kind: .type, description: "2-component uchar vector"),
        CompletionItem(text: "short2", kind: .type, description: "2-component short vector"),
        CompletionItem(text: "ushort2", kind: .type, description: "2-component ushort vector"),
        CompletionItem(text: "int2", kind: .type, description: "2-component int vector"),
        CompletionItem(text: "uint2", kind: .type, description: "2-component uint vector"),
        CompletionItem(text: "half2", kind: .type, description: "2-component half vector"),
        CompletionItem(text: "float2", kind: .type, description: "2-component float vector"),

        // Vector types (3 components)
        CompletionItem(text: "bool3", kind: .type, description: "3-component boolean vector"),
        CompletionItem(text: "char3", kind: .type, description: "3-component char vector"),
        CompletionItem(text: "uchar3", kind: .type, description: "3-component uchar vector"),
        CompletionItem(text: "short3", kind: .type, description: "3-component short vector"),
        CompletionItem(text: "ushort3", kind: .type, description: "3-component ushort vector"),
        CompletionItem(text: "int3", kind: .type, description: "3-component int vector"),
        CompletionItem(text: "uint3", kind: .type, description: "3-component uint vector"),
        CompletionItem(text: "half3", kind: .type, description: "3-component half vector"),
        CompletionItem(text: "float3", kind: .type, description: "3-component float vector"),

        // Vector types (4 components)
        CompletionItem(text: "bool4", kind: .type, description: "4-component boolean vector"),
        CompletionItem(text: "char4", kind: .type, description: "4-component char vector"),
        CompletionItem(text: "uchar4", kind: .type, description: "4-component uchar vector"),
        CompletionItem(text: "short4", kind: .type, description: "4-component short vector"),
        CompletionItem(text: "ushort4", kind: .type, description: "4-component ushort vector"),
        CompletionItem(text: "int4", kind: .type, description: "4-component int vector"),
        CompletionItem(text: "uint4", kind: .type, description: "4-component uint vector"),
        CompletionItem(text: "half4", kind: .type, description: "4-component half vector"),
        CompletionItem(text: "float4", kind: .type, description: "4-component float vector"),

        // Packed vector types
        CompletionItem(text: "packed_float3", kind: .type, description: "Packed 3-component float vector"),
        CompletionItem(text: "packed_float4", kind: .type, description: "Packed 4-component float vector"),
        CompletionItem(text: "packed_half3", kind: .type, description: "Packed 3-component half vector"),
        CompletionItem(text: "packed_half4", kind: .type, description: "Packed 4-component half vector"),

        // Matrix types
        CompletionItem(text: "float2x2", kind: .type, description: "2x2 float matrix"),
        CompletionItem(text: "float2x3", kind: .type, description: "2x3 float matrix"),
        CompletionItem(text: "float2x4", kind: .type, description: "2x4 float matrix"),
        CompletionItem(text: "float3x2", kind: .type, description: "3x2 float matrix"),
        CompletionItem(text: "float3x3", kind: .type, description: "3x3 float matrix"),
        CompletionItem(text: "float3x4", kind: .type, description: "3x4 float matrix"),
        CompletionItem(text: "float4x2", kind: .type, description: "4x2 float matrix"),
        CompletionItem(text: "float4x3", kind: .type, description: "4x3 float matrix"),
        CompletionItem(text: "float4x4", kind: .type, description: "4x4 float matrix"),

        // Texture types
        CompletionItem(text: "texture1d", kind: .type, description: "1D texture"),
        CompletionItem(text: "texture1d_array", kind: .type, description: "1D texture array"),
        CompletionItem(text: "texture2d", kind: .type, description: "2D texture"),
        CompletionItem(text: "texture2d_array", kind: .type, description: "2D texture array"),
        CompletionItem(text: "texture2d_ms", kind: .type, description: "2D multisample texture"),
        CompletionItem(text: "texture3d", kind: .type, description: "3D texture"),
        CompletionItem(text: "texturecube", kind: .type, description: "Cube texture"),
        CompletionItem(text: "texturecube_array", kind: .type, description: "Cube texture array"),

        // Depth textures
        CompletionItem(text: "depth2d", kind: .type, description: "2D depth texture"),
        CompletionItem(text: "depth2d_array", kind: .type, description: "2D depth texture array"),
        CompletionItem(text: "depthcube", kind: .type, description: "Cube depth texture"),

        // Sampler types
        CompletionItem(text: "sampler", kind: .type, description: "Texture sampler"),
        CompletionItem(text: "samplerstate", kind: .type, description: "Sampler state"),
    ]

    // MARK: - Built-in Functions

    static let builtInFunctions: [CompletionItem] = [
        // Math functions
        CompletionItem(text: "abs", kind: .function, description: "Absolute value", snippet: "abs($0)"),
        CompletionItem(text: "acos", kind: .function, description: "Arc cosine", snippet: "acos($0)"),
        CompletionItem(text: "asin", kind: .function, description: "Arc sine", snippet: "asin($0)"),
        CompletionItem(text: "atan", kind: .function, description: "Arc tangent", snippet: "atan($0)"),
        CompletionItem(text: "atan2", kind: .function, description: "Arc tangent of y/x", snippet: "atan2($0, $1)"),
        CompletionItem(text: "ceil", kind: .function, description: "Round up to nearest integer", snippet: "ceil($0)"),
        CompletionItem(text: "clamp", kind: .function, description: "Clamp value between min and max", snippet: "clamp($0, $1, $2)"),
        CompletionItem(text: "cos", kind: .function, description: "Cosine", snippet: "cos($0)"),
        CompletionItem(text: "cross", kind: .function, description: "Cross product", snippet: "cross($0, $1)"),
        CompletionItem(text: "degrees", kind: .function, description: "Convert radians to degrees", snippet: "degrees($0)"),
        CompletionItem(text: "distance", kind: .function, description: "Distance between two points", snippet: "distance($0, $1)"),
        CompletionItem(text: "dot", kind: .function, description: "Dot product", snippet: "dot($0, $1)"),
        CompletionItem(text: "exp", kind: .function, description: "Exponential function", snippet: "exp($0)"),
        CompletionItem(text: "exp2", kind: .function, description: "Base-2 exponential", snippet: "exp2($0)"),
        CompletionItem(text: "floor", kind: .function, description: "Round down to nearest integer", snippet: "floor($0)"),
        CompletionItem(text: "fma", kind: .function, description: "Fused multiply-add", snippet: "fma($0, $1, $2)"),
        CompletionItem(text: "fmax", kind: .function, description: "Maximum value", snippet: "fmax($0, $1)"),
        CompletionItem(text: "fmin", kind: .function, description: "Minimum value", snippet: "fmin($0, $1)"),
        CompletionItem(text: "fmod", kind: .function, description: "Floating-point remainder", snippet: "fmod($0, $1)"),
        CompletionItem(text: "fract", kind: .function, description: "Fractional part", snippet: "fract($0)"),
        CompletionItem(text: "length", kind: .function, description: "Vector length", snippet: "length($0)"),
        CompletionItem(text: "log", kind: .function, description: "Natural logarithm", snippet: "log($0)"),
        CompletionItem(text: "log2", kind: .function, description: "Base-2 logarithm", snippet: "log2($0)"),
        CompletionItem(text: "max", kind: .function, description: "Maximum value", snippet: "max($0, $1)"),
        CompletionItem(text: "min", kind: .function, description: "Minimum value", snippet: "min($0, $1)"),
        CompletionItem(text: "mix", kind: .function, description: "Linear interpolation", snippet: "mix($0, $1, $2)"),
        CompletionItem(text: "normalize", kind: .function, description: "Normalize vector", snippet: "normalize($0)"),
        CompletionItem(text: "pow", kind: .function, description: "Power function", snippet: "pow($0, $1)"),
        CompletionItem(text: "radians", kind: .function, description: "Convert degrees to radians", snippet: "radians($0)"),
        CompletionItem(text: "reflect", kind: .function, description: "Reflect vector", snippet: "reflect($0, $1)"),
        CompletionItem(text: "refract", kind: .function, description: "Refract vector", snippet: "refract($0, $1, $2)"),
        CompletionItem(text: "round", kind: .function, description: "Round to nearest integer", snippet: "round($0)"),
        CompletionItem(text: "rsqrt", kind: .function, description: "Reciprocal square root", snippet: "rsqrt($0)"),
        CompletionItem(text: "saturate", kind: .function, description: "Clamp to [0, 1]", snippet: "saturate($0)"),
        CompletionItem(text: "sign", kind: .function, description: "Sign of value", snippet: "sign($0)"),
        CompletionItem(text: "sin", kind: .function, description: "Sine", snippet: "sin($0)"),
        CompletionItem(text: "smoothstep", kind: .function, description: "Smooth interpolation", snippet: "smoothstep($0, $1, $2)"),
        CompletionItem(text: "sqrt", kind: .function, description: "Square root", snippet: "sqrt($0)"),
        CompletionItem(text: "step", kind: .function, description: "Step function", snippet: "step($0, $1)"),
        CompletionItem(text: "tan", kind: .function, description: "Tangent", snippet: "tan($0)"),
        CompletionItem(text: "trunc", kind: .function, description: "Truncate to integer", snippet: "trunc($0)"),

        // Geometric functions
        CompletionItem(text: "faceforward", kind: .function, description: "Orient normal to face viewer", snippet: "faceforward($0, $1, $2)"),

        // Texture sampling
        CompletionItem(text: "sample", kind: .function, description: "Sample texture", snippet: "sample($0, $1)"),
        CompletionItem(text: "read", kind: .function, description: "Read from texture", snippet: "read($0)"),
        CompletionItem(text: "write", kind: .function, description: "Write to texture", snippet: "write($0, $1)"),
        CompletionItem(text: "gather", kind: .function, description: "Gather texture samples", snippet: "gather($0, $1)"),
    ]

    // MARK: - Attributes

    static let attributes: [CompletionItem] = [
        CompletionItem(text: "[[stage_in]]", kind: .attribute, description: "Vertex function input"),
        CompletionItem(text: "[[position]]", kind: .attribute, description: "Vertex position output"),
        CompletionItem(text: "[[vertex_id]]", kind: .attribute, description: "Vertex ID"),
        CompletionItem(text: "[[instance_id]]", kind: .attribute, description: "Instance ID"),
        CompletionItem(text: "[[buffer(0)]]", kind: .attribute, description: "Buffer argument"),
        CompletionItem(text: "[[texture(0)]]", kind: .attribute, description: "Texture argument"),
        CompletionItem(text: "[[sampler(0)]]", kind: .attribute, description: "Sampler argument"),
        CompletionItem(text: "[[attribute(0)]]", kind: .attribute, description: "Vertex attribute"),
        CompletionItem(text: "[[color(0)]]", kind: .attribute, description: "Fragment color output"),
        CompletionItem(text: "[[thread_position_in_grid]]", kind: .attribute, description: "Thread position in grid"),
        CompletionItem(text: "[[thread_position_in_threadgroup]]", kind: .attribute, description: "Thread position in threadgroup"),
        CompletionItem(text: "[[threadgroup_position_in_grid]]", kind: .attribute, description: "Threadgroup position in grid"),
        CompletionItem(text: "[[threads_per_threadgroup]]", kind: .attribute, description: "Threads per threadgroup"),
    ]
}
