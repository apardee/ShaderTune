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
    @Binding var previewWidth: CGFloat

    var body: some View {
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
}
