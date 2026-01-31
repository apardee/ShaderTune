//
//  ProjectNavigatorView.swift
//  ShaderTune
//
//  Navigator view for shader projects showing passes instead of files.
//

import SwiftUI

/// View for navigating shader projects with multi-pass support
struct ProjectNavigatorView: View {
    let project: ShaderProject
    @Binding var selectedPass: ShaderPass?
    let passDiagnostics: [String: [CompilationDiagnostic]]

    @State private var isBuffersExpanded: Bool = true
    @State private var isOutputExpanded: Bool = true

    var body: some View {
        List(
            selection: Binding(
                get: { selectedPass?.id },
                set: { id in
                    selectedPass = project.allPasses.first { $0.id == id }
                }
            )
        ) {
            // Project header
            Section {
                HStack {
                    Image(systemName: "cube.fill")
                        .foregroundColor(.accentColor)
                    Text(project.name)
                        .font(.headline)
                }
            }

            // Buffers section
            if !project.buffers.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $isBuffersExpanded) {
                        ForEach(project.buffers) { buffer in
                            PassRow(
                                pass: buffer,
                                isSelected: selectedPass?.id == buffer.id,
                                diagnostics: passDiagnostics[buffer.name] ?? []
                            )
                            .tag(buffer.id)
                            .onTapGesture {
                                selectedPass = buffer
                            }
                        }
                    } label: {
                        Label("Buffers", systemImage: "square.stack")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Output section (main pass)
            Section {
                DisclosureGroup(isExpanded: $isOutputExpanded) {
                    PassRow(
                        pass: project.mainPass,
                        isSelected: selectedPass?.id == project.mainPass.id,
                        diagnostics: passDiagnostics[project.mainPass.name] ?? []
                    )
                    .tag(project.mainPass.id)
                    .onTapGesture {
                        selectedPass = project.mainPass
                    }
                } label: {
                    Label("Output", systemImage: "display")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

/// Row view for a single shader pass
struct PassRow: View {
    let pass: ShaderPass
    let isSelected: Bool
    let diagnostics: [CompilationDiagnostic]

    var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }

    var hasWarnings: Bool {
        !hasErrors && diagnostics.contains { $0.severity == .warning }
    }

    var body: some View {
        HStack {
            // Icon based on pass type
            Image(systemName: passIcon)
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(pass.name)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(pass.file)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            // Error/warning indicator
            if hasErrors {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } else if hasWarnings {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }

            // Feedback indicator
            if pass.feedback {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .help("Feedback enabled - can sample previous frame")
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private var passIcon: String {
        if pass.isMain {
            return "display"
        } else if pass.feedback {
            return "arrow.triangle.2.circlepath"
        } else {
            return "square.stack"
        }
    }

    private var iconColor: Color {
        if hasErrors {
            return .red
        } else if hasWarnings {
            return .yellow
        } else if isSelected {
            return .white
        } else if pass.isMain {
            return .green
        } else {
            return .accentColor
        }
    }
}

/// View for workspace mode showing multiple projects
struct WorkspaceNavigatorView: View {
    let projects: [ShaderProject]
    @Binding var selectedProject: ShaderProject?
    @Binding var selectedPass: ShaderPass?
    let passDiagnostics: [String: [CompilationDiagnostic]]

    var body: some View {
        List {
            ForEach(projects) { project in
                DisclosureGroup {
                    // Buffers
                    ForEach(project.buffers) { buffer in
                        PassRow(
                            pass: buffer,
                            isSelected: selectedPass?.id == buffer.id,
                            diagnostics: passDiagnostics[buffer.name] ?? []
                        )
                        .onTapGesture {
                            selectedProject = project
                            selectedPass = buffer
                        }
                    }

                    // Main pass
                    PassRow(
                        pass: project.mainPass,
                        isSelected: selectedPass?.id == project.mainPass.id,
                        diagnostics: passDiagnostics[project.mainPass.name] ?? []
                    )
                    .onTapGesture {
                        selectedProject = project
                        selectedPass = project.mainPass
                    }
                } label: {
                    HStack {
                        Image(systemName: "cube.fill")
                            .foregroundColor(
                                selectedProject?.id == project.id ? .accentColor : .secondary)
                        Text(project.name)
                            .font(.headline)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
