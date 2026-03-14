//
//  PreviewModeDetailView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct PreviewModeDetailView: View {
    @Bindable var state: EditorState

    @State private var showControls: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            PreviewWindowContent()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controlsBar
        }
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
