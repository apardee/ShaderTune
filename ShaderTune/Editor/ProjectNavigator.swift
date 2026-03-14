//
//  ProjectNavigator.swift
//  ShaderTune
//
//  Top-level workspace navigator: select, add, rename, and remove projects.
//

import SwiftUI

struct ProjectNavigator: View {
    @Binding var directoryURL: URL?
    @Binding var shaders: [Shader]
    @Binding var currentShader: Shader?

    let onSelectShader: (Shader) -> Void
    let onCreateShader: (URL, String) -> Void
    let onRenameShader: (Shader, String) -> Void
    let onRemoveShader: (Shader) -> Void

    @State private var showingNewProjectSheet = false
    @State private var shaderToDelete: Shader?
    @State private var shaderToRename: Shader?

    private enum Mode {
        case empty, singleProject, workspace, looseFiles
    }

    private var mode: Mode {
        guard directoryURL != nil else { return .empty }
        if !shaders.isEmpty { return .workspace }
        if currentShader != nil { return .singleProject }
        return .looseFiles
    }

    var body: some View {
        Group {
            switch mode {
            case .empty:
                ContentUnavailableView(
                    "No Folder Open",
                    systemImage: "folder.badge.plus",
                    description: Text("Open a folder via File → Open.")
                )
            case .singleProject:
                singleProjectView
            case .workspace:
                workspaceView
            case .looseFiles:
                looseFilesView
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            if let workspaceURL = directoryURL {
                NewWorkspaceProjectSheet(
                    parentURL: workspaceURL,
                    existingNames: Set(shaders.map { $0.name }),
                    onCreate: onCreateShader
                )
            }
        }
        .sheet(item: $shaderToRename) { project in
            RenameProjectSheet(
                currentName: project.name,
                existingNames: Set(shaders.map { $0.name }).subtracting([project.name])
            ) { newName in
                onRenameShader(project, newName)
            }
        }
    }

    // MARK: - Single Project

    private var singleProjectView: some View {
        List {
            if let project = currentShader {
                Section(directoryURL?.lastPathComponent ?? "Shader") {
                    Label(project.name, systemImage: "cube.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Workspace

    private var workspaceView: some View {
        List(
            selection: Binding(
                get: { currentShader?.id },
                set: { id in
                    if let project = shaders.first(where: { $0.id == id }) {
                        onSelectShader(project)
                    }
                }
            )
        ) {
            Section(directoryURL?.lastPathComponent ?? "Project") {
                ForEach(shaders) { project in
                    Label(project.name, systemImage: "cube.fill")
                        .tag(project.id)
                        .contextMenu {
                            Button("Rename...") {
                                shaderToRename = project
                            }
                            Divider()
                            Button("Remove Shader", role: .destructive) {
                                shaderToDelete = project
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("New Shader", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                Spacer()
            }
        }
        .confirmationDialog(
            "Remove Shader \"\(shaderToDelete?.name ?? "")\"",
            isPresented: Binding(
                get: { shaderToDelete != nil },
                set: { if !$0 { shaderToDelete = nil } }
            ),
            presenting: shaderToDelete
        ) { project in
            Button("Move to Trash", role: .destructive) {
                onRemoveShader(project)
                shaderToDelete = nil
            }
        } message: { _ in
            Text("The shader folder and all its contents will be moved to the Trash.")
        }
    }

    // MARK: - Loose Files

    private var looseFilesView: some View {
        List {
            if let dir = directoryURL {
                Section("Files") {
                    Label(dir.lastPathComponent, systemImage: "folder.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - Rename Sheet

private struct RenameProjectSheet: View {
    let currentName: String
    let existingNames: Set<String>
    let onRename: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    init(currentName: String, existingNames: Set<String>, onRename: @escaping (String) -> Void) {
        self.currentName = currentName
        self.existingNames = existingNames
        self.onRename = onRename
        self._name = State(initialValue: currentName)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isUnchanged: Bool { trimmed == currentName }
    private var hasConflict: Bool { existingNames.contains(trimmed) }
    private var isValid: Bool { !trimmed.isEmpty && !isUnchanged && !hasConflict }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Shader")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("New Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Shader name", text: $name)
                    .textFieldStyle(.roundedBorder)

                if hasConflict {
                    Text("A shader with this name already exists.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Text("The shader folder will be renamed to match.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Button("Rename") {
                    onRename(trimmed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

// MARK: - New Workspace Project Sheet

private struct NewWorkspaceProjectSheet: View {
    let parentURL: URL
    let existingNames: Set<String>
    let onCreate: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""

    private var trimmed: String { projectName.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool { !trimmed.isEmpty && !existingNames.contains(trimmed) }
    private var hasConflict: Bool { existingNames.contains(trimmed) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Shader")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Shader Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("MyShader", text: $projectName)
                    .textFieldStyle(.roundedBorder)

                if hasConflict {
                    Text("A shader with this name already exists.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if !trimmed.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will create:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(parentURL.appendingPathComponent(trimmed).path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Button("Create") {
                    onCreate(parentURL.appendingPathComponent(trimmed), trimmed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
