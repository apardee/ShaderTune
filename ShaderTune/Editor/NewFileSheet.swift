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

struct NewProjectSheet: View {
    let onCreate: (URL, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var projectName: String = ""
    @State private var parentDirectory: URL?
    @State private var showingDirectoryPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Shader Project")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Project Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("MyShader", text: $projectName)
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

            if let dir = parentDirectory, !projectName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will create:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dir.appendingPathComponent(sanitizedProjectName).path)
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
                    createProject()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private var sanitizedProjectName: String {
        // Replace spaces and special characters with underscores for folder name
        let trimmed = projectName.trimmingCharacters(in: .whitespaces)
        return trimmed.replacingOccurrences(
            of: "[^a-zA-Z0-9_-]",
            with: "_",
            options: .regularExpression
        )
    }

    private var isValid: Bool {
        !projectName.trimmingCharacters(in: .whitespaces).isEmpty && parentDirectory != nil
    }

    #if os(macOS)
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a location to create the project folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            parentDirectory = url
        }
    }
    #endif

    private func createProject() {
        guard let parent = parentDirectory else { return }

        let trimmedName = projectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let projectURL = parent.appendingPathComponent(sanitizedProjectName)
        onCreate(projectURL, trimmedName)
        dismiss()
    }
}
