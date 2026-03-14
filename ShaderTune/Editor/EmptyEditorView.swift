//
//  EmptyEditorView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 3/14/26.
//

import SwiftUI

struct EmptyEditorView: View {
    let hasDirectory: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(
                systemName: hasDirectory
                    ? "doc.text.magnifyingglass" : "folder.badge.plus"
            )
            .font(.system(size: 64))
            .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Shader Selected")
                    .font(.title2)
                    .fontWeight(.semibold)

                if hasDirectory {
                    Text(
                        "Select a Metal shader file (.metal) from the sidebar to begin editing"
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                } else {
                    Text("Open a folder (Cmd+O) or drag a shader file here to begin")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
