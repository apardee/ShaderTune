//
//  EditorContentPane.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct EditorContentPane: View {
    @Bindable var state: EditorState
    @Binding var showingFindReplace: Bool

    var body: some View {
        VStack(spacing: 0) {
            if showingFindReplace {
                FindReplaceView(
                    searchText: $state.searchText,
                    replaceText: $state.replaceText,
                    isVisible: $showingFindReplace,
                    onFind: state.findNext,
                    onReplace: state.replaceNext,
                    onReplaceAll: state.replaceAll
                )
            }

            if state.selectedFileURL == nil && state.shaderSource.isEmpty
                && state.currentShader == nil
            {
                EmptyEditorView(hasDirectory: state.selectedDirectoryURL != nil)
            } else {
                ZStack(alignment: .topLeading) {
                    ShaderEditorViewWrapper(
                        source: $state.shaderSource,
                        diagnostics: state.currentDiagnostics
                    )
                    .id(state.selectedFileURL)

                    if state.showingCompletions && !state.completions.isEmpty {
                        CompletionView(
                            completions: state.completions,
                            onSelect: { item in
                                state.insertCompletion(item)
                            },
                            onDismiss: {
                                state.showingCompletions = false
                            }
                        )
                        .offset(x: 100, y: 100)
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}
