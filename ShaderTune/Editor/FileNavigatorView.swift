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

    let onSelectFile: (URL) -> Void

    @State private var isRootExpanded: Bool = true

    var body: some View {
        if selectedDirectoryURL == nil {
            ContentUnavailableView(
                "No Folder Open",
                systemImage: "folder.badge.questionmark",
                description: Text("Use File → Open (Cmd+O)")
            )
        } else {
            fileTreeView
        }
    }

    private var fileTreeView: some View {
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
            }
        }
        .listStyle(.sidebar)
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
            }
        } else {
            Button(
                action: { onSelectFile(node.url) },
                label: {
                    HStack {
                        Label(node.name, systemImage: "doc.text.fill")
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(.plain)
            .tag(node.url)
        }
    }
}
