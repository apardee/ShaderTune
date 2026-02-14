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
                .foregroundColor(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Project Name:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("MyShader", text: $projectName)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.border, lineWidth: AppTheme.borderWidth)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Location:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                HStack {
                    if let dir = parentDirectory {
                        Text(dir.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(AppTheme.textPrimary)
                    } else {
                        Text("No location selected")
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button("Choose...") {
                        chooseDirectory()
                    }
                    .buttonStyle(.flat)
                }
                .padding(8)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.border, lineWidth: AppTheme.borderWidth)
                )
            }

            if let dir = parentDirectory, !projectName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Will create:")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(dir.appendingPathComponent(sanitizedProjectName).path)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.flat)
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createProject()
                }
                .buttonStyle(.flatPrimary)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(AppTheme.bg)
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
