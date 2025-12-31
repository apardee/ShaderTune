//
//  ContentView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var compiler: MetalCompilerService
    @State private var shaderSource = """
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

    // Fragment (Pixel) Shader - Animated gradient effect
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
    @State private var autoCompile = true
    @State private var debounceTask: Task<Void, Never>?
    @State private var showingTemplatePicker = false
    @State private var showingFindReplace = false
    @State private var searchText = ""
    @State private var replaceText = ""

    init() {
        guard let compiler = MetalCompilerService() else {
            fatalError("Metal is not supported on this device")
        }
        _compiler = StateObject(wrappedValue: compiler)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("ShaderTune")
                    .font(.headline)

                Text("Device: \(compiler.deviceInfo)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { showingTemplatePicker = true }) {
                    Label("Templates", systemImage: "doc.text")
                }
                .help("Choose from shader templates")

                Toggle("Auto-compile", isOn: $autoCompile)
                    .toggleStyle(.switch)
                    .help("Automatically compile shader as you type")

                if compiler.isCompiling {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 8)
                }

                Button("Compile") {
                    compileNow()
                }
                .buttonStyle(.borderedProminent)
                .disabled(compiler.isCompiling)
            }
            .padding()
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif

            // Find/Replace bar
            if showingFindReplace {
                FindReplaceView(
                    searchText: $searchText,
                    replaceText: $replaceText,
                    isVisible: $showingFindReplace,
                    onFind: findNext,
                    onReplace: replaceNext,
                    onReplaceAll: replaceAll
                )
            }

            // Editor and Error Display
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Editor
                    ShaderEditorView(source: $shaderSource)
                        .frame(height: geometry.size.height * 0.7)

                    Divider()

                    // Error Display
                    ErrorDisplayView(diagnostics: compiler.diagnostics)
                        .frame(height: geometry.size.height * 0.3)
                }
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerView { template in
                loadTemplate(template)
            }
        }
        #if os(macOS)
        .onKeyPress("f", phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                showingFindReplace.toggle()
                return .handled
            }
            return .ignored
        }
        #endif
        .onChange(of: shaderSource) { _, newValue in
            if autoCompile {
                scheduleCompilation(for: newValue)
            }
        }
        .onAppear {
            // Compile on first appearance if auto-compile is enabled
            if autoCompile {
                compileNow()
            }
        }
    }

    private func scheduleCompilation(for source: String) {
        // Cancel any existing debounce task
        debounceTask?.cancel()

        // Create a new debounced compilation task
        debounceTask = Task {
            // Wait for 1 second of inactivity
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Check if task was cancelled during sleep
            if !Task.isCancelled {
                await MainActor.run {
                    compiler.compile(source: source)
                }
            }
        }
    }

    private func compileNow() {
        // Cancel any pending debounced compilation
        debounceTask?.cancel()
        compiler.compile(source: shaderSource)
    }

    // MARK: - Template Loading

    private func loadTemplate(_ template: ShaderTemplate) {
        shaderSource = template.source
        if autoCompile {
            compileNow()
        }
    }

    // MARK: - Find/Replace

    private func findNext() {
        guard !searchText.isEmpty else { return }
        // Note: Basic implementation - in production would need cursor tracking
        // For now, just highlights that the feature exists
        print("Find: \(searchText)")
    }

    private func replaceNext() {
        guard !searchText.isEmpty else { return }
        // Find first occurrence and replace
        if let range = shaderSource.range(of: searchText) {
            shaderSource.replaceSubrange(range, with: replaceText)
        }
    }

    private func replaceAll() {
        guard !searchText.isEmpty else { return }
        shaderSource = shaderSource.replacingOccurrences(of: searchText, with: replaceText)
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 600)
}
