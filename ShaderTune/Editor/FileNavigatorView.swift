//
//  FileNavigatorView.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 1/4/26.
//

import SwiftUI

// Helper extension to unwrap optional bindings
extension Binding {
    func unwrap<T>() -> Binding<T>? where Value == T? {
        guard wrappedValue != nil else { return nil }
        nonisolated(unsafe) let binding = self
        return Binding<T>(
            get: { binding.wrappedValue! },
            set: { binding.wrappedValue = $0 }
        )
    }
}

struct FileNavigatorView: View {
    @Binding var selectedDirectoryURL: URL?
    @Binding var fileTree: [FileNode]
    @Binding var selectedFileURL: URL?

    let onSelectFile: (URL) -> Void

    @Binding var currentShader: Shader?
    @Binding var selectedPass: ShaderPass?
    let passDiagnostics: [String: [CompilationDiagnostic]]
    let onSelectPass: (ShaderPass) -> Void
    let onShaderUpdated: (Shader) -> Void

    @State private var isRootExpanded: Bool = true

    init(
        selectedDirectoryURL: Binding<URL?>,
        fileTree: Binding<[FileNode]>,
        selectedFileURL: Binding<URL?>,
        onSelectFile: @escaping (URL) -> Void,
        currentShader: Binding<Shader?> = .constant(nil),
        selectedPass: Binding<ShaderPass?> = .constant(nil),
        passDiagnostics: [String: [CompilationDiagnostic]] = [:],
        onSelectPass: @escaping (ShaderPass) -> Void = { _ in },
        onShaderUpdated: @escaping (Shader) -> Void = { _ in }
    ) {
        self._selectedDirectoryURL = selectedDirectoryURL
        self._fileTree = fileTree
        self._selectedFileURL = selectedFileURL
        self.onSelectFile = onSelectFile
        self._currentShader = currentShader
        self._selectedPass = selectedPass
        self.passDiagnostics = passDiagnostics
        self.onSelectPass = onSelectPass
        self.onShaderUpdated = onShaderUpdated
    }

    var body: some View {
        if selectedDirectoryURL == nil {
            ContentUnavailableView(
                "No Folder Open",
                systemImage: "folder.badge.questionmark",
                description: Text("Use File → Open (Cmd+O)")
            )
        } else if currentShader != nil {
            ProjectNavigatorView(
                project: $currentShader.unwrap()!,
                selectedPass: $selectedPass,
                passDiagnostics: passDiagnostics,
                onShaderUpdated: onShaderUpdated
            )
            .onChange(of: selectedPass) { _, newPass in
                if let pass = newPass {
                    onSelectPass(pass)
                }
            }
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
