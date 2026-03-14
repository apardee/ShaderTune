//
//  PreviewModeDetailView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct PreviewModeDetailView: View {
    @Bindable var state: EditorState
    @Binding var showShaderConfig: Bool
    @Binding var shaderConfigWidth: CGFloat

    @State private var showControls: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            PreviewWindowContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showShaderConfig, let shader = state.currentShader {
                configOverlay(shader: shader)
            }

            controlsBar
        }
        .clipped()
    }

    @ViewBuilder
    private func configOverlay(shader: Shader) -> some View {
        HStack(spacing: 0) {
            Spacer()
            Divider()
            ShaderConfigurationView(
                project: Binding(
                    get: { shader },
                    set: { state.currentShader = $0 }
                ),
                selectedPass: $state.selectedPass,
                passDiagnostics: state.compiler.passDiagnostics,
                onShaderUpdated: state.handleShaderUpdated
            )
            .frame(width: shaderConfigWidth)
            .onChange(of: state.selectedPass) { _, newPass in
                if let pass = newPass {
                    state.handlePassSelection(pass)
                }
            }
        }
        .transition(.move(edge: .trailing))
    }

    private var controlsBar: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    if state.isFileDirty {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.orange)
                            .help("Unsaved changes")
                    }
                    if state.compiler.isCompiling {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showShaderConfig.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.right")
                    }
                    .buttonStyle(.plain)
                    .help(
                        showShaderConfig
                            ? "Hide Shader Configuration" : "Show Shader Configuration"
                    )
                    .disabled(state.currentShader == nil)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .opacity(showControls ? 1 : 0)
                .padding(.trailing, 12)
            }
            .frame(height: 50)
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = hovering
                }
            }
            Spacer()
        }
    }
}
