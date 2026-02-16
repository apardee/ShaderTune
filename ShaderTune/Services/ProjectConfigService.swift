//
//  ProjectConfigService.swift
//  ShaderTune
//
//  Service for loading and saving shader project configurations.
//

import Foundation
import Yams

/// Errors that can occur when working with project configurations
enum ProjectConfigError: LocalizedError {
    case fileNotFound(URL)
    case parseError(String)
    case validationError([String])
    case writeError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Project configuration not found: \(url.lastPathComponent)"
        case .parseError(let message):
            return "Failed to parse project.yaml: \(message)"
        case .validationError(let errors):
            return "Project validation failed:\n" + errors.joined(separator: "\n")
        case .writeError(let message):
            return "Failed to save project.yaml: \(message)"
        }
    }
}

/// Service for loading and saving shader project configurations
class ProjectConfigService {
    /// The filename for project configuration
    static let configFileName = "project.yaml"

    /// Checks if a directory contains a project configuration
    /// - Parameter url: The directory URL to check
    /// - Returns: true if the directory contains a project.yaml file
    static func isProjectDirectory(_ url: URL) -> Bool {
        let configURL = url.appendingPathComponent(configFileName)
        return FileManager.default.fileExists(atPath: configURL.path)
    }

    /// Checks if a directory is a workspace (contains subdirectories with projects)
    /// - Parameter url: The directory URL to check
    /// - Returns: true if any immediate subdirectory is a project
    static func isWorkspaceDirectory(_ url: URL) -> Bool {
        // If it's already a project, it's not a workspace
        if isProjectDirectory(url) { return false }

        let fileManager = FileManager.default
        guard
            let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return false
        }

        for itemURL in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory),
                isDirectory.boolValue,
                isProjectDirectory(itemURL)
            {
                return true
            }
        }

        return false
    }

    /// Loads a project configuration from a directory
    /// - Parameter url: The project directory URL
    /// - Returns: The loaded ShaderProject
    /// - Throws: ProjectConfigError if loading fails
    static func loadProject(from url: URL) throws -> ShaderProject {
        let configURL = url.appendingPathComponent(configFileName)

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw ProjectConfigError.fileNotFound(configURL)
        }

        let yamlString: String
        do {
            yamlString = try String(contentsOf: configURL, encoding: .utf8)
        } catch {
            throw ProjectConfigError.parseError(
                "Could not read file: \(error.localizedDescription)")
        }

        let config: YAMLProjectConfig
        do {
            config = try YAMLDecoder().decode(YAMLProjectConfig.self, from: yamlString)
        } catch {
            throw ProjectConfigError.parseError(error.localizedDescription)
        }

        let project = convertToProject(config: config, projectURL: url)

        let validationErrors = project.validate()
        if !validationErrors.isEmpty {
            throw ProjectConfigError.validationError(validationErrors)
        }

        return project
    }

    /// Saves a project configuration to its directory
    /// - Parameter project: The project to save
    /// - Throws: ProjectConfigError if saving fails
    static func saveProject(_ project: ShaderProject) throws {
        let configURL = project.projectURL.appendingPathComponent(configFileName)
        let config = convertToYAMLConfig(project: project)

        let yamlString: String
        do {
            yamlString = try YAMLEncoder().encode(config)
        } catch {
            throw ProjectConfigError.writeError(
                "Could not encode YAML: \(error.localizedDescription)"
            )
        }

        do {
            try yamlString.write(to: configURL, atomically: true, encoding: .utf8)
        } catch {
            throw ProjectConfigError.writeError(error.localizedDescription)
        }
    }

    /// Finds all projects in a workspace directory
    /// - Parameter url: The workspace directory URL
    /// - Returns: Array of loaded projects
    static func findProjects(in url: URL) -> [ShaderProject] {
        var projects: [ShaderProject] = []

        let fileManager = FileManager.default
        guard
            let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        for itemURL in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDirectory),
                isDirectory.boolValue,
                isProjectDirectory(itemURL)
            {
                if let project = try? loadProject(from: itemURL) {
                    projects.append(project)
                }
            }
        }

        return projects.sorted { $0.name < $1.name }
    }

    /// Creates a new project with default configuration
    /// - Parameters:
    ///   - name: The project name
    ///   - url: The project directory URL
    /// - Returns: The created project
    static func createProject(name: String, at url: URL) throws -> ShaderProject {
        let fileManager = FileManager.default

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }

        // Create default main shader file
        let mainShaderFile = "image.metal"
        let mainShaderURL = url.appendingPathComponent(mainShaderFile)
        let defaultMainShader = """
            // Uniforms are provided automatically by ShaderTune
            // struct Uniforms {
            //     float time;
            //     float2 mouse;
            //     float2 resolution;
            //     float scale;
            // };

            fragment float4 fragmentFunc(
                float4 position [[position]],
                constant Uniforms& uniforms [[buffer(0)]]
            ) {
                float2 uv = position.xy / uniforms.resolution;
                return float4(uv.x, uv.y, 0.5 + 0.5 * sin(uniforms.time), 1.0);
            }
            """
        try defaultMainShader.write(to: mainShaderURL, atomically: true, encoding: .utf8)

        // Create project
        let mainPass = ShaderPass(
            name: "Main",
            file: mainShaderFile,
            isMain: true
        )

        let project = ShaderProject(
            name: name,
            mainPass: mainPass,
            buffers: [],
            projectURL: url
        )

        // Save configuration
        try saveProject(project)

        return project
    }

    /// Creates a new buffer and adds it to the project
    /// - Parameters:
    ///   - project: The project to add the buffer to
    ///   - name: The buffer name (e.g., "BufferA")
    ///   - feedback: Whether the buffer can sample its previous frame
    /// - Returns: The updated project with the new buffer
    static func addBuffer(
        to project: ShaderProject,
        name: String,
        feedback: Bool = false
    ) throws -> ShaderProject {
        // Create buffer filename from name (e.g., "BufferA" -> "buffer_a.metal")
        let filename = name.lowercased().replacingOccurrences(of: " ", with: "_") + ".metal"
        let fileURL = project.projectURL.appendingPathComponent(filename)

        // Create the buffer shader file
        let defaultBufferShader = """
            // Uniforms are provided automatically by ShaderTune
            // struct Uniforms {
            //     float time;
            //     float2 mouse;
            //     float2 resolution;
            //     float scale;
            // };

            fragment float4 fragmentFunc(
                float4 position [[position]],
                constant Uniforms& uniforms [[buffer(0)]]\(feedback ? ",\n    texture2d<float> previousFrame [[texture(7)]]  // Feedback from previous frame" : "")
            ) {
                float2 uv = position.xy / uniforms.resolution;
            \(feedback ? """

                // Sample previous frame for feedback effect
                constexpr sampler s(filter::linear);
                float4 previous = previousFrame.sample(s, uv);

                // Fade previous frame and add new content
                float3 color = previous.rgb * 0.98;

            """ : "    float3 color = float3(uv, 0.5 + 0.5 * sin(uniforms.time));\n")
                return float4(color, 1.0);
            }
            """
        try defaultBufferShader.write(to: fileURL, atomically: true, encoding: .utf8)

        // Create the new buffer pass
        let newBuffer = ShaderPass(
            name: name,
            file: filename,
            feedback: feedback,
            isMain: false
        )

        // Create updated project with the new buffer
        let updatedProject = project.withBuffer(newBuffer)

        // Save the updated project configuration
        try saveProject(updatedProject)

        return updatedProject
    }

    /// Reorders buffers in a project
    /// - Parameters:
    ///   - project: The project to modify
    ///   - newOrder: The new buffer order
    /// - Returns: The updated project
    static func reorderBuffers(
        in project: ShaderProject,
        newOrder: [ShaderPass]
    ) throws -> ShaderProject {
        let updatedProject = project.withReorderedBuffers(newOrder)
        try saveProject(updatedProject)
        return updatedProject
    }

    // MARK: - Private Helpers

    private static func convertToProject(
        config: YAMLProjectConfig, projectURL: URL
    )
        -> ShaderProject
    {
        // Convert main pass
        let mainInputs =
            config.main.inputs?.map {
                PassInput(buffer: $0.buffer, binding: $0.binding)
            } ?? []

        let mainPass = ShaderPass(
            name: "Main",
            file: config.main.file,
            function: config.main.function ?? "fragmentFunc",
            inputs: mainInputs,
            feedback: false,
            isMain: true
        )

        // Convert buffer passes
        let buffers =
            config.buffers?.map { buffer -> ShaderPass in
                let inputs =
                    buffer.inputs?.map {
                        PassInput(buffer: $0.buffer, binding: $0.binding)
                    } ?? []

                return ShaderPass(
                    name: buffer.name,
                    file: buffer.file,
                    function: buffer.function ?? "fragmentFunc",
                    inputs: inputs,
                    feedback: buffer.feedback ?? false,
                    isMain: false
                )
            } ?? []

        return ShaderProject(
            version: config.version ?? ShaderProject.currentVersion,
            name: config.name,
            mainPass: mainPass,
            buffers: buffers,
            projectURL: projectURL
        )
    }

    private static func convertToYAMLConfig(project: ShaderProject) -> YAMLProjectConfig {
        // Convert main pass
        let mainInputs: [YAMLPassInput]? =
            project.mainPass.inputs.isEmpty
            ? nil
            : project.mainPass.inputs.map { YAMLPassInput(buffer: $0.buffer, binding: $0.binding) }

        let mainConfig = YAMLMainPass(
            file: project.mainPass.file,
            function: project.mainPass.function == "fragmentFunc"
                ? nil : project.mainPass.function,
            inputs: mainInputs
        )

        // Convert buffer passes
        let buffers: [YAMLBufferPass]? =
            project.buffers.isEmpty
            ? nil
            : project.buffers.map { buffer in
                let inputs: [YAMLPassInput]? =
                    buffer.inputs.isEmpty
                    ? nil
                    : buffer.inputs.map { YAMLPassInput(buffer: $0.buffer, binding: $0.binding) }

                return YAMLBufferPass(
                    name: buffer.name,
                    file: buffer.file,
                    function: buffer.function == "fragmentFunc" ? nil : buffer.function,
                    inputs: inputs,
                    feedback: buffer.feedback ? true : nil
                )
            }

        return YAMLProjectConfig(
            version: project.version,
            name: project.name,
            main: mainConfig,
            buffers: buffers
        )
    }
}
