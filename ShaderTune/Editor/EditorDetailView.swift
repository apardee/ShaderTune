//
//  EditorDetailView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct EditorDetailView: View {
    @Environment(PreviewState.self) private var previewState
    @Bindable var state: EditorState

    @Binding var showingFindReplace: Bool
    @Binding var showShaderConfig: Bool
    @Binding var shaderConfigWidth: CGFloat
    @Binding var previewWidth: CGFloat

    @State private var shaderConfigDragStartWidth: CGFloat?

    private let shaderConfigMinWidth: CGFloat = 180
    private let shaderConfigMaxWidth: CGFloat = 520

    var body: some View {
        HStack(spacing: 0) {
            VSplitView {
                EditorContentPane(
                    state: state,
                    showingFindReplace: $showingFindReplace
                )
                .frame(minHeight: 300)

                if state.showDiagnostics {
                    DiagnosticsPane(
                        diagnostics: state.currentDiagnostics,
                        onDismiss: {
                            state.showDiagnostics = false
                        },
                        onSelectDiagnostic: { diagnostic in
                            print("Jump to line \(diagnostic.line)")
                        }
                    )
                    .frame(minHeight: 100, idealHeight: 200, maxHeight: 400)
                }
            }

            if showShaderConfig, let shader = state.currentShader {
                shaderConfigDivider
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
                .transition(.move(edge: .trailing))
            }
        }
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            if !previewState.isDetached {
                PreviewInsetView(
                    previewState: previewState,
                    previewWidth: $previewWidth
                )
                .padding(24)
            }
        }
    }

    private var shaderConfigDivider: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 8)
            .contentShape(Rectangle())
            #if os(macOS)
        .cursor(.resizeLeftRight)
            #endif
            .overlay(Divider(), alignment: .center)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if shaderConfigDragStartWidth == nil {
                            shaderConfigDragStartWidth = shaderConfigWidth
                        }
                        guard let startWidth = shaderConfigDragStartWidth else { return }
                        let delta = -(value.location.x - value.startLocation.x)
                        shaderConfigWidth = (startWidth + delta)
                            .clamped(to: shaderConfigMinWidth...shaderConfigMaxWidth)
                    }
                    .onEnded { _ in
                        shaderConfigDragStartWidth = nil
                    }
            )
    }
}
