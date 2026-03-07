//
//  ProjectConfigService.swift
//  ShaderTune
//
//  Service for loading and saving shader configurations.
//

import Foundation
import Yams

/// Errors that can occur when working with shader configurations
enum ProjectConfigError: LocalizedError {
    case fileNotFound(URL)
    case parseError(String)
    case validationError([String])
    case writeError(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Shader configuration not found: \(url.lastPathComponent)"
        case .parseError(let message):
            return "Failed to parse project.yaml: \(message)"
        case .validationError(let errors):
            return "Shader validation failed:\n" + errors.joined(separator: "\n")
        case .writeError(let message):
            return "Failed to save project.yaml: \(message)"
        }
    }
}

/// Service for loading and saving shader configurations
class ProjectConfigService {
    /// The filename for shader configuration
    static let configFileName = "project.yaml"

    /// Checks if a directory contains a shader configuration
    static func isShaderDirectory(_ url: URL) -> Bool {
        let configURL = url.appendingPathComponent(configFileName)
        return FileManager.default.fileExists(atPath: configURL.path)
    }

    /// Checks if a directory is a project (contains subdirectories with shaders)
    static func isProjectDirectory(_ url: URL) -> Bool {
        if isShaderDirectory(url) { return false }

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
                isShaderDirectory(itemURL)
            {
                return true
            }
        }

        return false
    }

    /// Loads a shader configuration from a directory
    static func loadShader(from url: URL) throws -> Shader {
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

        let shader = convertToShader(config: config, shaderURL: url)

        let validationErrors = shader.validate()
        if !validationErrors.isEmpty {
            throw ProjectConfigError.validationError(validationErrors)
        }

        return shader
    }

    /// Saves a shader configuration to its directory
    static func saveShader(_ shader: Shader) throws {
        let configURL = shader.projectURL.appendingPathComponent(configFileName)
        let config = convertToYAMLConfig(shader: shader)

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

    /// Finds all shaders in a project directory
    static func findShaders(in url: URL) -> [Shader] {
        var shaders: [Shader] = []

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
                isShaderDirectory(itemURL)
            {
                if let shader = try? loadShader(from: itemURL) {
                    shaders.append(shader)
                }
            }
        }

        return shaders.sorted { $0.name < $1.name }
    }

    /// Creates a new shader with default configuration
    static func createShader(name: String, at url: URL) throws -> Shader {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }

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

        let mainPass = ShaderPass(name: "Main", file: mainShaderFile, isMain: true)
        let shader = Shader(name: name, mainPass: mainPass, buffers: [], projectURL: url)
        try saveShader(shader)
        return shader
    }

    /// Creates a new buffer and adds it to the shader
    static func addBuffer(to shader: Shader, name: String, feedback: Bool = false) throws -> Shader {
        let filename = name.lowercased().replacingOccurrences(of: " ", with: "_") + ".metal"
        let fileURL = shader.projectURL.appendingPathComponent(filename)

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

        let newBuffer = ShaderPass(name: name, file: filename, feedback: feedback, isMain: false)
        let updated = shader.withBuffer(newBuffer)
        try saveShader(updated)
        return updated
    }

    /// Reorders buffers in a shader
    static func reorderBuffers(in shader: Shader, newOrder: [ShaderPass]) throws -> Shader {
        let updated = shader.withReorderedBuffers(newOrder)
        try saveShader(updated)
        return updated
    }

    // MARK: - Private Helpers

    private static func convertToShader(config: YAMLProjectConfig, shaderURL: URL) -> Shader {
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

        return Shader(
            version: config.version ?? Shader.currentVersion,
            name: config.name,
            mainPass: mainPass,
            buffers: buffers,
            projectURL: shaderURL
        )
    }

    private static func convertToYAMLConfig(shader: Shader) -> YAMLProjectConfig {
        let mainInputs: [YAMLPassInput]? =
            shader.mainPass.inputs.isEmpty
            ? nil
            : shader.mainPass.inputs.map { YAMLPassInput(buffer: $0.buffer, binding: $0.binding) }

        let mainConfig = YAMLMainPass(
            file: shader.mainPass.file,
            function: shader.mainPass.function == "fragmentFunc"
                ? nil : shader.mainPass.function,
            inputs: mainInputs
        )

        let buffers: [YAMLBufferPass]? =
            shader.buffers.isEmpty
            ? nil
            : shader.buffers.map { buffer in
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
            version: shader.version,
            name: shader.name,
            main: mainConfig,
            buffers: buffers
        )
    }
}
