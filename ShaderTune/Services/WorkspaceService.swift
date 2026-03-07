//
//  WorkspaceService.swift
//  ShaderTune
//
//  Service for analyzing directory structures and managing projects.
//

import Foundation

/// Service for analyzing directory structures
class WorkspaceService {
    /// Analyzes a directory to determine its type (shader, project, or loose files)
    static func analyzeDirectory(_ url: URL) -> DirectoryType {
        if ProjectConfigService.isShaderDirectory(url) {
            if let shader = try? ProjectConfigService.loadShader(from: url) {
                return .shader(shader)
            }
        }

        if ProjectConfigService.isProjectDirectory(url) {
            let shaders = ProjectConfigService.findShaders(in: url)
            if !shaders.isEmpty {
                return .project(shaders)
            }
        }

        return .looseFiles
    }

    /// Finds all metal files in a directory (for loose files mode)
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

    /// Creates a shader from a directory of loose files
    static func createShaderFromLooseFiles(
        at url: URL,
        name: String,
        mainFile: String
    ) throws -> Shader {
        let mainPass = ShaderPass(name: "Main", file: mainFile, isMain: true)
        let shader = Shader(name: name, mainPass: mainPass, buffers: [], projectURL: url)
        try ProjectConfigService.saveShader(shader)
        return shader
    }

    /// Adds a buffer pass to an existing shader
    static func addBuffer(
        to shader: Shader,
        name: String,
        file: String,
        feedback: Bool = false
    ) throws -> Shader {
        let newBuffer = ShaderPass(name: name, file: file, feedback: feedback, isMain: false)
        let updated = Shader(
            id: shader.id,
            name: shader.name,
            mainPass: shader.mainPass,
            buffers: shader.buffers + [newBuffer],
            projectURL: shader.projectURL
        )
        try ProjectConfigService.saveShader(updated)
        return updated
    }

    /// Removes a buffer pass from an existing shader
    static func removeBuffer(from shader: Shader, named bufferName: String) throws -> Shader {
        let updatedBuffers = shader.buffers.filter { $0.name != bufferName }

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

        let cleanedMainInputs = shader.mainPass.inputs.filter { $0.buffer != bufferName }
        let cleanedMainPass = ShaderPass(
            id: shader.mainPass.id,
            name: shader.mainPass.name,
            file: shader.mainPass.file,
            function: shader.mainPass.function,
            inputs: cleanedMainInputs,
            feedback: shader.mainPass.feedback,
            isMain: shader.mainPass.isMain
        )

        let updated = Shader(
            id: shader.id,
            name: shader.name,
            mainPass: cleanedMainPass,
            buffers: cleanedBuffers,
            projectURL: shader.projectURL
        )
        try ProjectConfigService.saveShader(updated)
        return updated
    }

    /// Updates a pass's input configuration
    static func updatePassInputs(
        shader: Shader,
        passName: String,
        inputs: [PassInput]
    ) throws -> Shader {
        var updatedMainPass = shader.mainPass
        var updatedBuffers = shader.buffers

        if passName == shader.mainPass.name {
            updatedMainPass = ShaderPass(
                id: shader.mainPass.id,
                name: shader.mainPass.name,
                file: shader.mainPass.file,
                function: shader.mainPass.function,
                inputs: inputs,
                feedback: shader.mainPass.feedback,
                isMain: shader.mainPass.isMain
            )
        } else {
            updatedBuffers = shader.buffers.map { buffer in
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

        let updated = Shader(
            id: shader.id,
            name: shader.name,
            mainPass: updatedMainPass,
            buffers: updatedBuffers,
            projectURL: shader.projectURL
        )
        try ProjectConfigService.saveShader(updated)
        return updated
    }
}
