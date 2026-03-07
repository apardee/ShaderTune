//
//  ProjectNavigator.swift
//  ShaderTune
//
//  Top-level workspace navigator: select, add, and remove projects.
//

import SwiftUI

struct ProjectNavigator: View {
    @Binding var directoryURL: URL?
    @Binding var workspaceProjects: [ShaderProject]
    @Binding var currentProject: ShaderProject?

    let onSelectProject: (ShaderProject) -> Void
    let onCreateProject: (URL, String) -> Void
    let onRemoveProject: (ShaderProject) -> Void

    @State private var showingNewProjectSheet = false
    @State private var projectToDelete: ShaderProject?

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

// MARK: - New Workspace Project Sheet

private struct NewWorkspaceProjectSheet: View {
    let parentURL: URL
    let existingNames: Set<String>
    let onCreate: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""

    private var sanitizedName: String {
        projectName.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(
                of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
    }

    private var isValid: Bool {
        let trimmed = projectName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !existingNames.contains(trimmed)
    }

    private var nameConflict: Bool {
        existingNames.contains(projectName.trimmingCharacters(in: .whitespaces))
    }

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

                if nameConflict {
                    Text("A project with this name already exists.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            if !projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will create:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(parentURL.appendingPathComponent(sanitizedName).path)
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
                    let name = projectName.trimmingCharacters(in: .whitespaces)
                    let url = parentURL.appendingPathComponent(sanitizedName)
                    onCreate(url, name)
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
