//
//  FileNavigatorView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 1/4/26.
//

import SwiftUI

struct FileNavigatorView: View {
    @Binding var selectedDirectoryURL: URL?
    @Binding var fileTree: [FileNode]
    @Binding var selectedFileURL: URL?

    let onSelectFolder: () -> Void
    let onSelectFile: (URL) -> Void

    @State private var isRootExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with folder picker
            HStack {
                Spacer()
                Button(action: onSelectFolder) {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Select Folder (Cmd+O)")
            }
            .padding()
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif

            Divider()

            // File tree
            if selectedDirectoryURL == nil {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No folder selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Select Folder") {
                        onSelectFolder()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedFileURL) {
                    DisclosureGroup(isExpanded: $isRootExpanded) {
                        ForEach(fileTree, id: \.id) { node in
                            FileNodeView(
                                node: node,
                                selectedFileURL: $selectedFileURL,
                                onSelectFile: onSelectFile
                            )
                        }
                    } label: {
                        Label(
                            selectedDirectoryURL?.lastPathComponent ?? "Project",
                            systemImage: "folder.fill"
                        )
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

/// Recursive view for rendering file tree nodes
struct FileNodeView: View {
    let node: FileNode
    @Binding var selectedFileURL: URL?
    let onSelectFile: (URL) -> Void

    @State private var isExpanded: Bool = true

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children ?? [], id: \.id) { child in
                    FileNodeView(
                        node: child,
                        selectedFileURL: $selectedFileURL,
                        onSelectFile: onSelectFile
                    )
                }
            } label: {
                Label(node.name, systemImage: "folder.fill")
                    .foregroundColor(.accentColor)
            }
        } else {
            Button(
                action: { onSelectFile(node.url) },
                label: {
                    HStack {
                        Label(node.name, systemImage: "doc.text.fill")
                            .foregroundColor(selectedFileURL == node.url ? .white : .primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(.plain)
            .tag(node.url)
        }
    }
}
