//
//  WorkspaceService.swift
//  ShaderTune
//
//  Service for analyzing directory structures and managing workspaces.
//

import Foundation

/// Service for analyzing directory structures
class WorkspaceService {
    /// Analyzes a directory to determine its type (project, workspace, or loose files)
    /// - Parameter url: The directory URL to analyze
    /// - Returns: The detected directory type
    static func analyzeDirectory(_ url: URL) -> DirectoryType {
        // Check if it's a project directory
        if ProjectConfigService.isProjectDirectory(url) {
            if let project = try? ProjectConfigService.loadProject(from: url) {
                return .project(project)
            }
        }

        // Check if it's a workspace (contains project subdirectories)
        if ProjectConfigService.isWorkspaceDirectory(url) {
            let projects = ProjectConfigService.findProjects(in: url)
            if !projects.isEmpty {
                return .workspace(projects)
            }
        }

        // Default to loose files
        return .looseFiles
    }

    /// Finds all metal files in a directory (for loose files mode)
    /// - Parameter url: The directory URL to scan
    /// - Returns: Array of metal file URLs
    static func findMetalFiles(in url: URL) -> [URL] {
        var metalFiles: [URL] = []

        let fileManager = FileManager.default
        guard
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "metal" {
            metalFiles.append(fileURL)
        }

        return metalFiles.sorted { $0.path < $1.path }
    }

    /// Creates a project from a directory of loose files
    /// - Parameters:
    ///   - url: The directory URL
    ///   - name: The project name
    ///   - mainFile: The main shader file (relative path)
    /// - Returns: The created project
    static func createProjectFromLooseFiles(
        at url: URL,
        name: String,
        mainFile: String
    ) throws -> ShaderProject {
        let mainPass = ShaderPass(
            name: "Main",
            file: mainFile,
            isMain: true
        )

        let project = ShaderProject(
            name: name,
            mainPass: mainPass,
            buffers: [],
            projectURL: url
        )

        try ProjectConfigService.saveProject(project)
        return project
    }

    /// Adds a buffer pass to an existing project
    /// - Parameters:
    ///   - project: The project to modify
    ///   - name: The buffer name
    ///   - file: The shader file path
    ///   - feedback: Whether the buffer can sample itself
    /// - Returns: The updated project
    static func addBuffer(
        to project: ShaderProject,
        name: String,
        file: String,
        feedback: Bool = false
    ) throws -> ShaderProject {
        let newBuffer = ShaderPass(
            name: name,
            file: file,
            feedback: feedback,
            isMain: false
        )

        let updatedProject = ShaderProject(
            id: project.id,
            name: project.name,
            mainPass: project.mainPass,
            buffers: project.buffers + [newBuffer],
            projectURL: project.projectURL
        )

        try ProjectConfigService.saveProject(updatedProject)
        return updatedProject
    }

    /// Removes a buffer pass from an existing project
    /// - Parameters:
    ///   - project: The project to modify
    ///   - bufferName: The name of the buffer to remove
    /// - Returns: The updated project
    static func removeBuffer(
        from project: ShaderProject, named bufferName: String
    ) throws
        -> ShaderProject
    {
        let updatedBuffers = project.buffers.filter { $0.name != bufferName }

        // Also remove any references to this buffer from other passes
        let cleanedBuffers = updatedBuffers.map { buffer -> ShaderPass in
            let cleanedInputs = buffer.inputs.filter { $0.buffer != bufferName }
            return ShaderPass(
                id: buffer.id,
                name: buffer.name,
                file: buffer.file,
                function: buffer.function,
                inputs: cleanedInputs,
                feedback: buffer.feedback,
                isMain: buffer.isMain
            )
        }

        // Clean main pass inputs too
        let cleanedMainInputs = project.mainPass.inputs.filter { $0.buffer != bufferName }
        let cleanedMainPass = ShaderPass(
            id: project.mainPass.id,
            name: project.mainPass.name,
            file: project.mainPass.file,
            function: project.mainPass.function,
            inputs: cleanedMainInputs,
            feedback: project.mainPass.feedback,
            isMain: project.mainPass.isMain
        )

        let updatedProject = ShaderProject(
            id: project.id,
            name: project.name,
            mainPass: cleanedMainPass,
            buffers: cleanedBuffers,
            projectURL: project.projectURL
        )

        try ProjectConfigService.saveProject(updatedProject)
        return updatedProject
    }

    /// Updates a pass's input configuration
    /// - Parameters:
    ///   - project: The project to modify
    ///   - passName: The name of the pass to update
    ///   - inputs: The new inputs for the pass
    /// - Returns: The updated project
    static func updatePassInputs(
        project: ShaderProject,
        passName: String,
        inputs: [PassInput]
    ) throws -> ShaderProject {
        var updatedMainPass = project.mainPass
        var updatedBuffers = project.buffers

        if passName == project.mainPass.name {
            updatedMainPass = ShaderPass(
                id: project.mainPass.id,
                name: project.mainPass.name,
                file: project.mainPass.file,
                function: project.mainPass.function,
                inputs: inputs,
                feedback: project.mainPass.feedback,
                isMain: project.mainPass.isMain
            )
        } else {
            updatedBuffers = project.buffers.map { buffer in
                if buffer.name == passName {
                    return ShaderPass(
                        id: buffer.id,
                        name: buffer.name,
                        file: buffer.file,
                        function: buffer.function,
                        inputs: inputs,
                        feedback: buffer.feedback,
                        isMain: buffer.isMain
                    )
                }
                return buffer
            }
        }

        let updatedProject = ShaderProject(
            id: project.id,
            name: project.name,
            mainPass: updatedMainPass,
            buffers: updatedBuffers,
            projectURL: project.projectURL
        )

        try ProjectConfigService.saveProject(updatedProject)
        return updatedProject
    }
}
