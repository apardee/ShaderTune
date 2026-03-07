//
//  PreviewWindowContent.swift
//  ShaderTune
//

import Metal
import SwiftUI

struct PreviewWindowContent: View {
    @Environment(PreviewState.self) private var previewState

    var body: some View {
        @Bindable var state = previewState

        if state.currentProject != nil && !state.passLibraries.isEmpty {
            RendererView(
                mousePosition: $state.mousePosition,
                compiledLibrary: $state.compiledLibrary,
                project: $state.currentProject,
                passLibraries: $state.passLibraries
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    state.mousePosition = location
                case .ended:
                    break
                }
            }
        } else if state.selectedFileURL != nil && state.compiledLibrary != nil {
            RendererView(
                mousePosition: $state.mousePosition,
                compiledLibrary: $state.compiledLibrary
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    state.mousePosition = location
                case .ended:
                    break
                }
            }
        } else {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text("No Shader Preview")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Compile your shader to see the preview")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
