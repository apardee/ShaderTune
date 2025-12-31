# ShaderTune Resources

## Metal Syntax Highlighting

### Current Implementation

ShaderTune currently uses **C++ syntax highlighting** for Metal Shading Language (MSL) files. This is because:

1. MSL is based on C++14
2. The CodeEditor package uses Highlightr, which wraps Highlight.js
3. Highlightr doesn't support custom language registration at runtime
4. Highlight.js doesn't have built-in MSL support

### What Gets Highlighted (C++ Mode)

✅ **Working:**
- Standard C++ keywords: `if`, `else`, `for`, `while`, `switch`, `return`, etc.
- C++ types: `int`, `float`, `double`, `bool`, `void`, etc.
- Preprocessor directives: `#include`, `#define`, `#ifdef`, etc.
- Comments: `//` and `/* */`
- Strings and numbers
- Operators and punctuation
- Namespace syntax: `::`

❌ **Not Highlighted:**
- MSL-specific keywords: `kernel`, `vertex`, `fragment`
- MSL address space qualifiers: `constant`, `device`, `threadgroup`
- MSL built-in types: `float4`, `texture2d`, `sampler`
- MSL attributes: `[[stage_in]]`, `[[buffer(0)]]`, `[[texture(0)]]`
- MSL built-in functions: Many Metal-specific functions

### The `metal.js` File

This directory contains `metal.js`, a complete Highlight.js language definition for Metal Shading Language. This file includes:

- **Function qualifiers**: `kernel`, `vertex`, `fragment`
- **Address space qualifiers**: `constant`, `device`, `threadgroup`, `threadgroup_imageblock`
- **All MSL types**: Scalars, vectors (2/3/4), packed vectors, matrices
- **Texture types**: `texture1d`, `texture2d`, `texture3d`, `texturecube`, etc.
- **Depth textures**: `depth2d`, `depthcube`, etc.
- **Sampler types**: `sampler`, `samplerstate`
- **Ray tracing types**: For Apple Silicon ray tracing
- **Built-in functions**: Math, geometric, texture sampling, atomic operations, etc.
- **Attributes**: All `[[attribute]]` syntax
- **Preprocessor support**: `#include`, `#define`, etc.

### How to Use the MSL Definition (Future)

There are three ways to enable proper MSL syntax highlighting:

#### Option 1: Switch to CodeEditorView Package

```swift
// Replace CodeEditor with CodeEditorView
import CodeEditorView

// CodeEditorView supports custom language servers and syntax highlighting
```

**Pros:**
- Native SwiftUI
- Better control over editor
- Supports inline error markers
- Can implement custom syntax highlighting

**Cons:**
- Pre-release quality
- More complex integration
- Requires custom syntax implementation

#### Option 2: Fork Highlightr

1. Fork the Highlightr repository
2. Add `metal.js` to the Highlight.js bundle
3. Rebuild the `highlight.min.js` file
4. Use the forked version in your Package.swift

**Pros:**
- Keeps using CodeEditor
- Full MSL syntax support

**Cons:**
- Maintenance burden
- Have to maintain fork
- Highlight.js bundle rebuild complexity

#### Option 3: Build Native Syntax Highlighter

Use `metal.js` as a reference to implement native Swift-based syntax highlighting with TextKit or similar.

**Pros:**
- Full control
- Best performance
- Native integration

**Cons:**
- Significant development effort
- Complex implementation

### Example MSL Code

Here's how MSL code looks with current C++ highlighting:

```metal
#include <metal_stdlib>          // ✅ Highlighted (preprocessor)
using namespace metal;           // ✅ Highlighted (namespace)

struct VertexIn {                // ✅ Highlighted (struct)
    float4 position [[attribute(0)]];  // ⚠️ 'float4' not highlighted, 'float' is
    float2 texCoord [[attribute(1)]];  // ❌ Attributes not highlighted
};

vertex VertexOut vertexShader(  // ❌ 'vertex' not highlighted as keyword
    VertexIn in [[stage_in]]     // ❌ Attributes not highlighted
) {
    VertexOut out;
    out.position = in.position;  // ✅ Basic syntax highlighted
    return out;                  // ✅ Highlighted
}

fragment float4 fragmentShader(  // ❌ 'fragment' not highlighted
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]]  // ❌ 'texture2d' not highlighted
) {
    constexpr sampler s;         // ⚠️ 'constexpr' highlighted, 'sampler' not
    return tex.sample(s, in.texCoord);
}
```

### Recommendations

**For now:**
- C++ mode provides decent highlighting for basic syntax
- Most important elements (control flow, types, comments) work

**For the future:**
- Consider switching to CodeEditorView for better editor control
- Implement custom syntax highlighting using the `metal.js` definition as reference
- Or wait for Highlight.js to add official MSL support

### References

- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Highlight.js Language Definition Guide](https://highlightjs.readthedocs.io/en/latest/language-guide.html)
- [CodeEditorView](https://github.com/mchakravarty/CodeEditorView)
- [Highlightr](https://github.com/raspu/Highlightr)
