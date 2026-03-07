//
//  ProjectNavigatorView.swift
//  ShaderTune
//
//  Navigator view for shader projects showing passes instead of files.
//

import SwiftUI
import UniformTypeIdentifiers

/// View for navigating shader projects with multi-pass support
struct ProjectNavigatorView: View {
    @Binding var project: Shader
    @Binding var selectedPass: ShaderPass?
    let passDiagnostics: [String: [CompilationDiagnostic]]
    let onShaderUpdated: (Shader) -> Void

    @State private var isBuffersExpanded: Bool = true
    @State private var isOutputExpanded: Bool = true
    @State private var showingNewBufferSheet: Bool = false
    @State private var draggedBuffer: ShaderPass?

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
                        .foregroundStyle(.tint)
                    Text(project.name)
                        .font(.headline)
                    Spacer()
                    Text(project.version)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Buffers section
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
                        .onDrag {
                            draggedBuffer = buffer
                            return NSItemProvider(object: buffer.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: BufferDropDelegate(
                                buffer: buffer,
                                buffers: project.buffers,
                                draggedBuffer: $draggedBuffer,
                                onReorder: handleBufferReorder
                            )
                        )
                    }

                    // Add Buffer button
                    Button {
                        showingNewBufferSheet = true
                    } label: {
                        Label("Add Buffer", systemImage: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                } label: {
                    Label("Buffers", systemImage: "square.stack")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showingNewBufferSheet) {
            NewBufferSheet(
                existingBufferNames: Set(project.buffers.map { $0.name }),
                onCreate: handleCreateBuffer
            )
        }
    }

    private func handleCreateBuffer(name: String, feedback: Bool) {
        do {
            let updatedProject = try ProjectConfigService.addBuffer(
                to: project,
                name: name,
                feedback: feedback
            )
            project = updatedProject
            onShaderUpdated(updatedProject)

            // Select the new buffer
            if let newBuffer = updatedProject.buffers.last {
                selectedPass = newBuffer
            }
        } catch {
            print("Failed to create buffer: \(error)")
        }
    }

    private func handleBufferReorder(_ newOrder: [ShaderPass]) {
        do {
            let updatedProject = try ProjectConfigService.reorderBuffers(
                in: project,
                newOrder: newOrder
            )
            project = updatedProject
            onShaderUpdated(updatedProject)
        } catch {
            print("Failed to reorder buffers: \(error)")
        }
    }
}

/// Drop delegate for buffer reordering
struct BufferDropDelegate: DropDelegate {
    let buffer: ShaderPass
    let buffers: [ShaderPass]
    @Binding var draggedBuffer: ShaderPass?
    let onReorder: ([ShaderPass]) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggedBuffer = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedBuffer = draggedBuffer,
            draggedBuffer.id != buffer.id,
            let fromIndex = buffers.firstIndex(where: { $0.id == draggedBuffer.id }),
            let toIndex = buffers.firstIndex(where: { $0.id == buffer.id })
        else {
            return
        }

        var newBuffers = buffers
        newBuffers.move(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        onReorder(newBuffers)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

/// Sheet for creating a new buffer
struct NewBufferSheet: View {
    let existingBufferNames: Set<String>
    let onCreate: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var bufferName: String = ""
    @State private var enableFeedback: Bool = false

    private var suggestedName: String {
        // Suggest BufferA, BufferB, etc. based on existing buffers
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for letter in letters {
            let name = "Buffer\(letter)"
            if !existingBufferNames.contains(name) {
                return name
            }
        }
        return "Buffer\(existingBufferNames.count + 1)"
    }

    private var isValid: Bool {
        let trimmed = bufferName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !existingBufferNames.contains(trimmed)
    }

    private var nameError: String? {
        let trimmed = bufferName.trimmingCharacters(in: .whitespaces)
        if existingBufferNames.contains(trimmed) {
            return "A buffer with this name already exists"
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Buffer")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Buffer Name:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(suggestedName, text: $bufferName)
                    .textFieldStyle(.roundedBorder)
                    .onAppear {
                        bufferName = suggestedName
                    }

                if let error = nameError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Toggle("Enable Feedback", isOn: $enableFeedback)
                .help("Allow this buffer to sample its previous frame (for accumulation effects)")

            if enableFeedback {
                Text("The buffer can sample its previous frame at texture(7)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    let name = bufferName.trimmingCharacters(in: .whitespaces)
                    onCreate(name, enableFeedback)
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

                Text(pass.file)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
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
            return .accentColor
        } else if pass.isMain {
            return .green
        } else {
            return .accentColor
        }
    }
}

/// View for workspace mode showing multiple projects (kept for reference; workspace navigation is handled by ProjectNavigator)
private struct WorkspaceNavigatorView: View {
    @Binding var projects: [Shader]
    @Binding var selectedProject: Shader?
    @Binding var selectedPass: ShaderPass?
    let passDiagnostics: [String: [CompilationDiagnostic]]
    let onShaderUpdated: (Shader) -> Void

    @State private var showingNewBufferSheet: Bool = false
    @State private var newBufferTargetProject: Shader?

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

                    // Add Buffer button
                    Button {
                        newBufferTargetProject = project
                        showingNewBufferSheet = true
                    } label: {
                        Label("Add Buffer", systemImage: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

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
                            .foregroundStyle(
                                selectedProject?.id == project.id ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary)
                            )
                        Text(project.name)
                            .font(.headline)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showingNewBufferSheet) {
            if let targetProject = newBufferTargetProject {
                NewBufferSheet(
                    existingBufferNames: Set(targetProject.buffers.map { $0.name }),
                    onCreate: { name, feedback in
                        handleCreateBuffer(in: targetProject, name: name, feedback: feedback)
                    }
                )
            }
        }
    }

    private func handleCreateBuffer(in project: Shader, name: String, feedback: Bool) {
        do {
            let updatedProject = try ProjectConfigService.addBuffer(
                to: project,
                name: name,
                feedback: feedback
            )

            // Update the projects list
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = updatedProject
            }

            selectedProject = updatedProject
            onShaderUpdated(updatedProject)

            // Select the new buffer
            if let newBuffer = updatedProject.buffers.last {
                selectedPass = newBuffer
            }
        } catch {
            print("Failed to create buffer: \(error)")
        }
    }
}
