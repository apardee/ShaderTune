import SwiftUI
import CodeEditor

struct ShaderEditorView: View {
    @Binding var source: String

    // Use C++ mode as MSL is based on C++14
    // This provides better highlighting than GLSL for Metal shaders
    // Note: MSL-specific keywords (kernel, vertex, fragment, etc.) won't be highlighted
    // until we switch to an editor that supports custom language definitions
    @State private var language = CodeEditor.Language.cpp
    @State private var theme = CodeEditor.ThemeName.pojoaque
    @State private var fontSize: CGFloat = 14

    var body: some View {
        CodeEditor(
            source: $source,
            language: language,
            theme: theme,
            fontSize: $fontSize
        )
    }
}

#Preview {
    @Previewable @State var sampleShader = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void simpleKernel(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        float4 color = inTexture.read(gid);
        outTexture.write(color, gid);
    }
    """

    ShaderEditorView(source: $sampleShader)
}
