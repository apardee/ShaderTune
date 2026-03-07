//
//  ProjectNavigator.swift
//  ShaderTune
//
//  Top-level workspace navigator: select, add, rename, and remove projects.
//

import SwiftUI

struct ProjectNavigator: View {
    @Binding var directoryURL: URL?
    @Binding var workspaceProjects: [ShaderProject]
    @Binding var currentProject: ShaderProject?

    let onSelectProject: (ShaderProject) -> Void
    let onCreateProject: (URL, String) -> Void
    let onRenameProject: (ShaderProject, String) -> Void
    let onRemoveProject: (ShaderProject) -> Void

    @State private var showingNewProjectSheet = false
    @State private var projectToDelete: ShaderProject?
    @State private var projectToRename: ShaderProject?

    private enum Mode {
        case empty, singleProject, workspace, looseFiles
    }

    private var mode: Mode {
        guard directoryURL != nil else { return .empty }
        if !workspaceProjects.isEmpty { return .workspace }
        if currentProject != nil { return .singleProject }
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
                    existingNames: Set(workspaceProjects.map { $0.name }),
                    onCreate: onCreateProject
                )
            }
        }
        .sheet(item: $projectToRename) { project in
            RenameProjectSheet(
                currentName: project.name,
                existingNames: Set(workspaceProjects.map { $0.name }).subtracting([project.name])
            ) { newName in
                onRenameProject(project, newName)
            }
        }
    }

    // MARK: - Single Project

    private var singleProjectView: some View {
        List {
            if let project = currentProject {
                Section(directoryURL?.lastPathComponent ?? "Project") {
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
                get: { currentProject?.id },
                set: { id in
                    if let project = workspaceProjects.first(where: { $0.id == id }) {
                        onSelectProject(project)
                    }
                }
            )
        ) {
            Section(directoryURL?.lastPathComponent ?? "Workspace") {
                ForEach(workspaceProjects) { project in
                    Label(project.name, systemImage: "cube.fill")
                        .tag(project.id)
                        .contextMenu {
                            Button("Rename...") {
                                projectToRename = project
                            }
                            Divider()
                            Button("Remove Project", role: .destructive) {
                                projectToDelete = project
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
                    Label("New Project", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                Spacer()
            }
            .background(.bar)
        }
        .confirmationDialog(
            "Remove \"\(projectToDelete?.name ?? "")\"",
            isPresented: Binding(
                get: { projectToDelete != nil },
                set: { if !$0 { projectToDelete = nil } }
            ),
            presenting: projectToDelete
        ) { project in
            Button("Move to Trash", role: .destructive) {
                onRemoveProject(project)
                projectToDelete = nil
            }
        } message: { _ in
            Text("The project folder and all its contents will be moved to the Trash.")
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
            Text("Rename Project")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("New Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Project name", text: $name)
                    .textFieldStyle(.roundedBorder)

                if hasConflict {
                    Text("A project with this name already exists.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Text("The project folder will be renamed to match.")
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
            Text("New Project")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Project Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("MyShader", text: $projectName)
                    .textFieldStyle(.roundedBorder)

                if hasConflict {
                    Text("A project with this name already exists.")
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
