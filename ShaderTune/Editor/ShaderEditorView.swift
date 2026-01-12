@preconcurrency import CodeEditorView
import LanguageSupport
import SwiftUI

struct ShaderEditorView: View {
    @Binding var source: String
    @Binding var messages: Set<TextLocated<LanguageSupport.Message>>
    @State private var position: CodeEditor.Position = CodeEditor.Position()

    var body: some View {
        CodeEditor(
            text: $source,
            position: $position,
            messages: $messages,
            language: .msl()
        )
        .environment(\.codeEditorTheme, Theme.defaultDark)
    }
}

/// Wrapper that converts CompilationDiagnostics to CodeEditorView messages
struct ShaderEditorViewWrapper: View {
    @Binding var source: String
    let diagnostics: [CompilationDiagnostic]

    @State private var messages: Set<TextLocated<LanguageSupport.Message>> = []

    var body: some View {
        ShaderEditorView(source: $source, messages: $messages)
            .onChange(of: diagnostics) { _, newDiagnostics in
                updateMessages(newDiagnostics)
            }
            .onAppear {
                updateMessages(diagnostics)
            }
    }

    private func updateMessages(_ diagnostics: [CompilationDiagnostic]) {
        let newMessages: [TextLocated<LanguageSupport.Message>] = diagnostics.compactMap {
            diagnostic in
            // Metal compiler uses 1-based line and column numbers
            let location = TextLocation(
                oneBasedLine: diagnostic.line, column: diagnostic.column ?? 1)
            let category: LanguageSupport.Message.Category =
                diagnostic.severity == .error ? .error : .warning
            let message = LanguageSupport.Message(
                category: category,
                length: 1,  // Underline at least 1 character
                summary: diagnostic.message,
                description: nil
            )
            return TextLocated(location: location, entity: message)
        }
        messages = Set(newMessages)
    }
}

#Preview {
    @Previewable @State var source = """
        #include <metal_stdlib>
        using namespace metal;

        fragment float4 fragmentShader(float2 uv [[stage_in]]) {
            return float4(uv.x, uv.y, 0.5, 1.0);
        }
        """

    ShaderEditorViewWrapper(source: $source, diagnostics: [])
        .frame(width: 600, height: 400)
}
