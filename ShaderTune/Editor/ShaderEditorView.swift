import SwiftUI
import CodeEditor

struct ShaderEditorView: View {
    @Binding var source: String
    @State private var language = CodeEditor.Language(rawValue: "glsl")
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
