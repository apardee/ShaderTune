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

    // Project mode support
    @Binding var currentProject: ShaderProject?
    @Binding var selectedPass: ShaderPass?
    @Binding var workspaceProjects: [ShaderProject]
    let passDiagnostics: [String: [CompilationDiagnostic]]
    let onSelectPass: (ShaderPass) -> Void
    let onProjectUpdated: (ShaderProject) -> Void

    @State private var isRootExpanded: Bool = true

    init(
        selectedDirectoryURL: Binding<URL?>,
        fileTree: Binding<[FileNode]>,
        selectedFileURL: Binding<URL?>,
        onSelectFile: @escaping (URL) -> Void,
        currentProject: Binding<ShaderProject?> = .constant(nil),
        selectedPass: Binding<ShaderPass?> = .constant(nil),
        workspaceProjects: Binding<[ShaderProject]> = .constant([]),
        passDiagnostics: [String: [CompilationDiagnostic]] = [:],
        onSelectPass: @escaping (ShaderPass) -> Void = { _ in },
        onProjectUpdated: @escaping (ShaderProject) -> Void = { _ in }
    ) {
        self._selectedDirectoryURL = selectedDirectoryURL
        self._fileTree = fileTree
        self._selectedFileURL = selectedFileURL
        self.onSelectFile = onSelectFile
        self._currentProject = currentProject
        self._selectedPass = selectedPass
        self._workspaceProjects = workspaceProjects
        self.passDiagnostics = passDiagnostics
        self.onSelectPass = onSelectPass
        self.onProjectUpdated = onProjectUpdated
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedDirectoryURL == nil {
                // No folder selected
                emptyStateView
            } else if currentProject != nil {
                // Project mode - show passes
                ProjectNavigatorView(
                    project: $currentProject.unwrap()!,
                    selectedPass: $selectedPass,
                    passDiagnostics: passDiagnostics,
                    onProjectUpdated: onProjectUpdated
                )
                .onChange(of: selectedPass) { _, newPass in
                    if let pass = newPass {
                        onSelectPass(pass)
                    }
                }
            } else if !workspaceProjects.isEmpty {
                // Workspace mode - show multiple projects
                WorkspaceNavigatorView(
                    projects: $workspaceProjects,
                    selectedProject: $currentProject,
                    selectedPass: $selectedPass,
                    passDiagnostics: passDiagnostics,
                    onProjectUpdated: onProjectUpdated
                )
                .onChange(of: selectedPass) { _, newPass in
                    if let pass = newPass {
                        onSelectPass(pass)
                    }
                }
            } else {
                // Loose files mode - show file tree
                fileTreeView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary)
            Text("No folder selected")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Text("Use File → Open (Cmd+O)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg)
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
                .foregroundColor(AppTheme.accent)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppTheme.bg)
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
                    .foregroundColor(AppTheme.accent)
            }
        } else {
            Button(
                action: { onSelectFile(node.url) },
                label: {
                    HStack {
                        Label(node.name, systemImage: "doc.text.fill")
                            .foregroundColor(
                                selectedFileURL == node.url
                                    ? AppTheme.accent : AppTheme.textPrimary
                            )
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        selectedFileURL == node.url
                            ? AppTheme.selection : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .contentShape(Rectangle())
                }
            )
            .buttonStyle(.plain)
            .tag(node.url)
        }
    }
}
