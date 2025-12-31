/*
 * Metal Shading Language (MSL) syntax definition for Highlight.js
 *
 * Language: Metal Shading Language
 * Description: Apple's Metal Shading Language for GPU programming
 * Author: ShaderTune
 * Category: graphics, gpu
 *
 * Based on: C++14, GLSL, HLSL
 *
 * NOTE: This file is for documentation and future use. The current CodeEditor
 * package does not support custom language registration at runtime. To use this:
 * 1. Switch to a different editor package that supports custom languages, OR
 * 2. Fork Highlightr and add this definition to the Highlight.js bundle, OR
 * 3. Use this as reference when implementing native syntax highlighting
 */

export default function(hljs) {
  const METAL_KEYWORDS = {
    // Function qualifiers
    keyword: [
      'kernel',
      'vertex',
      'fragment',
      // Access qualifiers
      'constant',
      'device',
      'threadgroup',
      'threadgroup_imageblock',
      // Address space qualifiers (legacy)
      '__constant',
      '__device',
      '__threadgroup',
      // Type qualifiers
      'const',
      'constexpr',
      'static',
      'volatile',
      // Control flow
      'if',
      'else',
      'switch',
      'case',
      'default',
      'for',
      'while',
      'do',
      'break',
      'continue',
      'return',
      'discard_fragment',
      // Namespace
      'namespace',
      'using',
      'metal',
      // Templates
      'template',
      'typename',
      // Other
      'struct',
      'enum',
      'union',
      'typedef'
    ],

    // Built-in types
    type: [
      // Scalar types
      'void',
      'bool',
      'char',
      'uchar',
      'short',
      'ushort',
      'int',
      'uint',
      'long',
      'ulong',
      'half',
      'float',
      'double',
      'size_t',
      'ptrdiff_t',

      // Vector types (2, 3, 4 components)
      'bool2', 'bool3', 'bool4',
      'char2', 'char3', 'char4',
      'uchar2', 'uchar3', 'uchar4',
      'short2', 'short3', 'short4',
      'ushort2', 'ushort3', 'ushort4',
      'int2', 'int3', 'int4',
      'uint2', 'uint3', 'uint4',
      'half2', 'half3', 'half4',
      'float2', 'float3', 'float4',

      // Packed vector types
      'packed_char2', 'packed_char3', 'packed_char4',
      'packed_uchar2', 'packed_uchar3', 'packed_uchar4',
      'packed_short2', 'packed_short3', 'packed_short4',
      'packed_ushort2', 'packed_ushort3', 'packed_ushort4',
      'packed_int2', 'packed_int3', 'packed_int4',
      'packed_uint2', 'packed_uint3', 'packed_uint4',
      'packed_half2', 'packed_half3', 'packed_half4',
      'packed_float2', 'packed_float3', 'packed_float4',

      // Matrix types
      'float2x2', 'float2x3', 'float2x4',
      'float3x2', 'float3x3', 'float3x4',
      'float4x2', 'float4x3', 'float4x4',
      'half2x2', 'half2x3', 'half2x4',
      'half3x2', 'half3x3', 'half3x4',
      'half4x2', 'half4x3', 'half4x4',

      // Texture types
      'texture1d',
      'texture1d_array',
      'texture2d',
      'texture2d_array',
      'texture2d_ms',
      'texture2d_ms_array',
      'texture3d',
      'texturecube',
      'texturecube_array',
      'texture_buffer',

      // Depth texture types
      'depth2d',
      'depth2d_array',
      'depth2d_ms',
      'depth2d_ms_array',
      'depthcube',
      'depthcube_array',

      // Sampler types
      'sampler',
      'samplerstate',

      // Ray tracing types
      'ray_data',
      'raytracing_acceleration_structure',
      'intersection_query',
      'intersection_result',

      // Other resource types
      'atomic_int',
      'atomic_uint',
      'imageblock',
      'imageblock_data',
      'visible_function_table'
    ],

    literal: [
      'true',
      'false',
      'nullptr'
    ],

    built_in: [
      // Math functions
      'abs', 'acos', 'acosh', 'asin', 'asinh', 'atan', 'atan2', 'atanh',
      'ceil', 'clamp', 'cos', 'cosh', 'cross', 'degrees', 'distance',
      'dot', 'exp', 'exp2', 'fabs', 'floor', 'fma', 'fmax', 'fmin',
      'fmod', 'fract', 'frexp', 'ldexp', 'length', 'log', 'log2', 'log10',
      'max', 'min', 'mix', 'modf', 'normalize', 'pow', 'radians',
      'reflect', 'refract', 'round', 'rsqrt', 'saturate', 'sign', 'sin',
      'sinh', 'smoothstep', 'sqrt', 'step', 'tan', 'tanh', 'trunc',

      // Geometric functions
      'faceforward',

      // Relational functions
      'all', 'any', 'select',

      // Integer functions
      'popcount', 'reverse_bits', 'clz', 'ctz',

      // Common functions
      'isfinite', 'isinf', 'isnan', 'isnormal', 'signbit',

      // Pack/unpack functions
      'pack_float_to_snorm4x8', 'pack_float_to_unorm4x8',
      'unpack_snorm4x8_to_float', 'unpack_unorm4x8_to_float',

      // Texture sampling functions
      'sample', 'read', 'write', 'gather',

      // Atomic functions
      'atomic_store', 'atomic_load', 'atomic_exchange',
      'atomic_compare_exchange_weak', 'atomic_fetch_add',
      'atomic_fetch_sub', 'atomic_fetch_and', 'atomic_fetch_or',
      'atomic_fetch_xor', 'atomic_fetch_min', 'atomic_fetch_max',

      // Synchronization functions
      'threadgroup_barrier', 'simdgroup_barrier',

      // SIMD group functions
      'simd_broadcast', 'simd_shuffle', 'simd_shuffle_and_fill_up',
      'simd_shuffle_down', 'simd_shuffle_rotate_down', 'simd_shuffle_rotate_up',
      'simd_shuffle_up', 'simd_shuffle_xor', 'quad_broadcast',

      // Ray tracing functions
      'intersect'
    ]
  };

  const PREPROCESSOR = {
    className: 'meta',
    begin: /#\s*[a-z]+\b/,
    end: /$/,
    keywords: {
      keyword: 'if else elif endif define undef warning error line pragma ifdef ifndef include'
    },
    contains: [
      {
        begin: /\\\n/,
        relevance: 0
      },
      hljs.inherit(hljs.C_LINE_COMMENT_MODE),
      hljs.inherit(hljs.C_BLOCK_COMMENT_MODE)
    ]
  };

  const ATTRIBUTE = {
    className: 'meta',
    begin: /\[\[/,
    end: /\]\]/,
    contains: [
      {
        className: 'meta-string',
        begin: /[a-z_][a-z0-9_]*/,
        keywords: {
          // Vertex function attributes
          'stage_in vertex_id instance_id base_vertex base_instance': '',
          // Fragment function attributes
          'color early_fragment_tests point_coord front_facing sample_id': '',
          'sample_mask position': '',
          // Kernel function attributes
          'thread_position_in_grid thread_position_in_threadgroup': '',
          'threadgroup_position_in_grid threads_per_threadgroup': '',
          'threads_per_simdgroup thread_index_in_simdgroup': '',
          'thread_index_in_threadgroup threadgroups_per_grid': '',
          // Resource attributes
          'buffer texture sampler threadgroup_imageblock': ''
        }
      },
      {
        className: 'number',
        begin: /\(\d+\)/
      }
    ]
  };

  const NUMBER = {
    className: 'number',
    variants: [
      { begin: '\\b(0b[01\']+)' },
      { begin: '\\b(0x[0-9a-fA-F\']+)' },
      { begin: '\\b([0-9][0-9\']*\\.?[0-9]*([eE][-+]?[0-9]+)?)[fFhH]?' }
    ],
    relevance: 0
  };

  return {
    name: 'Metal',
    aliases: ['metal', 'msl'],
    keywords: METAL_KEYWORDS,
    contains: [
      PREPROCESSOR,
      ATTRIBUTE,
      hljs.C_LINE_COMMENT_MODE,
      hljs.C_BLOCK_COMMENT_MODE,
      NUMBER,
      hljs.QUOTE_STRING_MODE,
      {
        className: 'string',
        begin: /'(\\?.)/
      }
    ]
  };
}
