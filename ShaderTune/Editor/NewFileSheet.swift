//
//  NewProjectSheet.swift
//  ShaderTune
//
//  Created by Anthony Pardee on 12/31/25.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

/// Sheet for creating a new workspace. The workspace folder is named by the user;
/// a default project named "ShaderProject" is created inside it automatically.
struct NewProjectSheet: View {
    let onCreate: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var workspaceName: String = ""
    @State private var parentDirectory: URL?

    private static let defaultProjectName = "ShaderProject"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Workspace Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("MyWorkspace", text: $workspaceName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Location:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let dir = parentDirectory {
                        Text(dir.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No location selected")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseDirectory()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(8)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
            }

            if let dir = parentDirectory, !workspaceName.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will create:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(
                        dir
                            .appendingPathComponent(sanitizedWorkspaceName)
                            .appendingPathComponent(Self.defaultProjectName)
                            .path
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createWorkspace()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private var sanitizedWorkspaceName: String {
        workspaceName.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
    }

    private var isValid: Bool {
        !workspaceName.trimmingCharacters(in: .whitespaces).isEmpty && parentDirectory != nil
    }

    #if os(macOS)
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a location for the new workspace"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            parentDirectory = url
        }
    }
    #endif

    private func createWorkspace() {
        guard let parent = parentDirectory,
            !workspaceName.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        let workspaceURL = parent.appendingPathComponent(sanitizedWorkspaceName)
        onCreate(workspaceURL, Self.defaultProjectName)
        dismiss()
    }
}
