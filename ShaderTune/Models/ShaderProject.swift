//
//  ShaderProject.swift
//  ShaderTune
//
//  Multi-pass shader project model for ShaderToy-style buffer rendering.
//

import Foundation

/// Represents an input to a shader pass (a buffer that the pass can sample)
struct PassInput: Codable, Equatable, Hashable {
    /// Name of the buffer to sample from
    let buffer: String

    /// Texture binding index (0-6 for buffer inputs, 7 reserved for feedback)
    let binding: Int
}

/// Represents a single rendering pass (either a buffer or the main output)
struct ShaderPass: Identifiable, Equatable, Hashable {
    let id: UUID

    /// Pass name (e.g., "BufferA", "Main")
    let name: String

    /// Relative path to the shader file
    let file: String

    /// Function name in the shader (defaults to "fragmentFunc")
    let function: String

    /// Input buffers this pass samples from
    let inputs: [PassInput]

    /// Whether this pass can sample its own previous frame (texture 7)
    let feedback: Bool

    /// Whether this is the main output pass
    let isMain: Bool

    init(
        id: UUID = UUID(),
        name: String,
        file: String,
        function: String = "fragmentFunc",
        inputs: [PassInput] = [],
        feedback: Bool = false,
        isMain: Bool = false
    ) {
        self.id = id
        self.name = name
        self.file = file
        self.function = function
        self.inputs = inputs
        self.feedback = feedback
        self.isMain = isMain
    }
}

/// Represents a shader project with multi-pass rendering support
struct ShaderProject: Identifiable, Equatable {
    let id: UUID

    /// Project name
    let name: String

    /// The main output pass
    let mainPass: ShaderPass

    /// Buffer passes (render to textures)
    let buffers: [ShaderPass]

    /// URL to the project directory
    let projectURL: URL

    init(
        id: UUID = UUID(),
        name: String,
        mainPass: ShaderPass,
        buffers: [ShaderPass],
        projectURL: URL
    ) {
        self.id = id
        self.name = name
        self.mainPass = mainPass
        self.buffers = buffers
        self.projectURL = projectURL
    }

    /// All passes in the project (buffers + main)
    var allPasses: [ShaderPass] {
        buffers + [mainPass]
    }

    /// Returns the pass with the given name, or nil if not found
    func pass(named name: String) -> ShaderPass? {
        if mainPass.name == name { return mainPass }
        return buffers.first { $0.name == name }
    }

    /// Returns the file URL for a pass
    func fileURL(for pass: ShaderPass) -> URL {
        projectURL.appendingPathComponent(pass.file)
    }

    /// Returns passes in topological order (dependencies before dependents)
    /// This ensures buffers are rendered before passes that sample them
    func passesInRenderOrder() -> [ShaderPass] {
        var result: [ShaderPass] = []
        var visited: Set<String> = []

        func visit(_ pass: ShaderPass) {
            guard !visited.contains(pass.name) else { return }
            visited.insert(pass.name)

            // Visit dependencies first
            for input in pass.inputs {
                if let dependency = buffers.first(where: { $0.name == input.buffer }) {
                    visit(dependency)
                }
            }

            result.append(pass)
        }

        // Visit all buffers first
        for buffer in buffers {
            visit(buffer)
        }

        // Main pass last
        visit(mainPass)

        return result
    }

    /// Validates the project configuration
    func validate() -> [String] {
        var errors: [String] = []

        // Check main pass file exists
        let mainFileURL = fileURL(for: mainPass)
        if !FileManager.default.fileExists(atPath: mainFileURL.path) {
            errors.append("Main shader file not found: \(mainPass.file)")
        }

        // Check buffer files exist
        for buffer in buffers {
            let bufferFileURL = fileURL(for: buffer)
            if !FileManager.default.fileExists(atPath: bufferFileURL.path) {
                errors.append("Buffer shader file not found: \(buffer.file)")
            }
        }

        // Check for duplicate buffer names
        let bufferNames = buffers.map { $0.name }
        let uniqueNames = Set(bufferNames)
        if bufferNames.count != uniqueNames.count {
            errors.append("Duplicate buffer names found")
        }

        // Check for invalid input references
        let validBufferNames = Set(bufferNames)
        for pass in allPasses {
            for input in pass.inputs {
                if !validBufferNames.contains(input.buffer) {
                    errors.append(
                        "Pass '\(pass.name)' references unknown buffer '\(input.buffer)'")
                }
            }
        }

        // Check for circular dependencies (excluding self-feedback which is allowed)
        if hasCyclicDependency() {
            errors.append("Circular dependency detected between buffers")
        }

        // Check binding indices are valid (0-6 for buffers, 7 reserved for feedback)
        for pass in allPasses {
            for input in pass.inputs {
                if input.binding < 0 || input.binding > 6 {
                    errors.append(
                        "Invalid binding index \(input.binding) in pass '\(pass.name)'. Use 0-6 for buffer inputs."
                    )
                }
            }
        }

        return errors
    }

    /// Checks for cyclic dependencies (excluding self-feedback)
    private func hasCyclicDependency() -> Bool {
        var visiting: Set<String> = []
        var visited: Set<String> = []

        func hasCycle(_ passName: String) -> Bool {
            if visiting.contains(passName) { return true }
            if visited.contains(passName) { return false }

            visiting.insert(passName)

            if let pass = pass(named: passName) {
                for input in pass.inputs {
                    // Skip self-references (allowed for feedback)
                    if input.buffer == passName { continue }
                    if hasCycle(input.buffer) { return true }
                }
            }

            visiting.remove(passName)
            visited.insert(passName)
            return false
        }

        for buffer in buffers where hasCycle(buffer.name) {
            return true
        }

        return false
    }
}

// MARK: - YAML Configuration Structures

/// YAML representation of a pass input
struct YAMLPassInput: Codable {
    let buffer: String
    let binding: Int
}

/// YAML representation of a buffer pass
struct YAMLBufferPass: Codable {
    let name: String
    let file: String
    let function: String?
    let inputs: [YAMLPassInput]?
    let feedback: Bool?
}

/// YAML representation of the main pass
struct YAMLMainPass: Codable {
    let file: String
    let function: String?
    let inputs: [YAMLPassInput]?
}

/// YAML representation of a project configuration
struct YAMLProjectConfig: Codable {
    let name: String
    let main: YAMLMainPass
    let buffers: [YAMLBufferPass]?
}

// MARK: - Workspace Types

/// Represents the type of directory structure detected
enum DirectoryType: Equatable {
    /// A project directory (contains project.yaml)
    case project(ShaderProject)

    /// A workspace containing multiple projects
    case workspace([ShaderProject])

    /// Loose files (no project.yaml found)
    case looseFiles
}
