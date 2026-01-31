import Foundation
import Metal
import Observation

/// Service responsible for compiling Metal shader source code and reporting diagnostics
@MainActor @Observable
class MetalCompilerService {
    private let device: MTLDevice
    var diagnostics: [CompilationDiagnostic] = []
    var compiledLibrary: MTLLibrary?
    var isCompiling: Bool = false

    /// Per-pass diagnostics (keyed by pass name)
    var passDiagnostics: [String: [CompilationDiagnostic]] = [:]

    /// Per-pass compiled libraries (keyed by pass name)
    var passLibraries: [String: MTLLibrary] = [:]

    init?() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        self.device = device
    }

    /// Compiles the given Metal shader source code
    /// - Parameter source: The Metal Shading Language source code
    func compile(source: String) {
        isCompiling = true
        diagnostics = []

        do {
            let options = MTLCompileOptions()
            options.mathMode = .safe
            options.languageVersion = .version3_2

            let library = try device.makeLibrary(source: source, options: options)
            self.compiledLibrary = library
            self.diagnostics = []
        } catch let error as NSError {
            self.diagnostics = parseError(error)
        }

        isCompiling = false
    }

    /// Compiles a single shader pass
    /// - Parameters:
    ///   - source: The Metal Shading Language source code
    ///   - passName: The name of the pass (for diagnostics tracking)
    /// - Returns: The compiled MTLLibrary, or nil if compilation failed
    func compilePass(source: String, passName: String) -> MTLLibrary? {
        isCompiling = true
        passDiagnostics[passName] = []

        defer { isCompiling = false }

        do {
            let options = MTLCompileOptions()
            options.mathMode = .safe
            options.languageVersion = .version3_2

            let library = try device.makeLibrary(source: source, options: options)
            passLibraries[passName] = library
            passDiagnostics[passName] = []
            return library
        } catch let error as NSError {
            let errors = parseError(error, passName: passName)
            passDiagnostics[passName] = errors

            // Also add to global diagnostics with pass prefix
            diagnostics.append(contentsOf: errors)

            return nil
        }
    }

    /// Compiles all passes in a project
    /// - Parameter project: The shader project to compile
    /// - Returns: Dictionary of compiled libraries keyed by pass name
    func compileProject(_ project: ShaderProject) -> [String: MTLLibrary] {
        isCompiling = true
        diagnostics = []
        passDiagnostics = [:]
        passLibraries = [:]

        defer { isCompiling = false }

        var libraries: [String: MTLLibrary] = [:]

        for pass in project.allPasses {
            let fileURL = project.fileURL(for: pass)

            guard let source = try? String(contentsOf: fileURL, encoding: .utf8) else {
                let error = CompilationDiagnostic(
                    line: 1,
                    column: nil,
                    severity: .error,
                    message: "[\(pass.name)] Could not read shader file: \(pass.file)"
                )
                diagnostics.append(error)
                passDiagnostics[pass.name] = [error]
                continue
            }

            if let library = compilePassSource(source: source, passName: pass.name) {
                libraries[pass.name] = library
            }
        }

        passLibraries = libraries
        return libraries
    }

    /// Internal compile method that doesn't set isCompiling (for use in compileProject)
    private func compilePassSource(source: String, passName: String) -> MTLLibrary? {
        do {
            let options = MTLCompileOptions()
            options.mathMode = .safe
            options.languageVersion = .version3_2

            let library = try device.makeLibrary(source: source, options: options)
            passDiagnostics[passName] = []
            return library
        } catch let error as NSError {
            let errors = parseError(error, passName: passName)
            passDiagnostics[passName] = errors
            diagnostics.append(contentsOf: errors)
            return nil
        }
    }

    /// Gets diagnostics for a specific pass
    func diagnostics(for passName: String) -> [CompilationDiagnostic] {
        return passDiagnostics[passName] ?? []
    }

    /// Clears all pass-related state
    func clearPassState() {
        passDiagnostics = [:]
        passLibraries = [:]
    }

    /// Parses Metal compiler error messages into structured diagnostics
    /// - Parameters:
    ///   - error: The NSError from makeLibrary
    ///   - passName: Optional pass name to prefix error messages with
    /// - Returns: An array of CompilationDiagnostic objects
    private func parseError(_ error: NSError, passName: String? = nil) -> [CompilationDiagnostic] {
        let message = error.localizedDescription

        // Metal error format: "program_source:12:5: error: message text"
        // or "program_source:12: error: message text"
        let pattern = #"program_source:(\d+)(?::(\d+))?:\s*(error|warning):\s*(.+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        else {
            // Fallback: return a generic diagnostic
            let errorMessage = passName != nil ? "[\(passName!)] \(message)" : message
            return [
                CompilationDiagnostic(
                    line: 1,
                    column: nil,
                    severity: .error,
                    message: errorMessage
                )
            ]
        }

        var diagnostics: [CompilationDiagnostic] = []
        let range = NSRange(message.startIndex..., in: message)

        regex.enumerateMatches(in: message, range: range) { match, _, _ in
            guard let match = match else { return }

            // Extract line number
            guard let lineRange = Range(match.range(at: 1), in: message),
                let line = Int(message[lineRange])
            else { return }

            // Extract column number (optional)
            var column: Int?
            if match.range(at: 2).location != NSNotFound,
                let columnRange = Range(match.range(at: 2), in: message)
            {
                column = Int(message[columnRange])
            }

            // Extract severity
            guard let severityRange = Range(match.range(at: 3), in: message) else { return }
            let severityStr = String(message[severityRange])
            let severity: DiagnosticSeverity =
                severityStr.lowercased() == "error" ? .error : .warning

            // Extract message (with optional pass name prefix)
            guard let messageRange = Range(match.range(at: 4), in: message) else { return }
            var errorMessage = String(message[messageRange])
            if let passName = passName {
                errorMessage = "[\(passName)] \(errorMessage)"
            }

            diagnostics.append(
                CompilationDiagnostic(
                    line: line,
                    column: column,
                    severity: severity,
                    message: errorMessage
                ))
        }

        // If no diagnostics were parsed, return a generic one
        if diagnostics.isEmpty {
            let errorMessage = passName != nil ? "[\(passName!)] \(message)" : message
            diagnostics.append(
                CompilationDiagnostic(
                    line: 1,
                    column: nil,
                    severity: .error,
                    message: errorMessage
                ))
        }

        return diagnostics
    }

    /// Returns information about the Metal device
    var deviceInfo: String {
        return device.name
    }
}
