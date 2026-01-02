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
        compiledLibrary = nil

        do {
            let options = MTLCompileOptions()
            options.fastMathEnabled = false
            options.languageVersion = .version3_2

            let library = try device.makeLibrary(source: source, options: options)
            self.compiledLibrary = library
            self.diagnostics = []
        } catch let error as NSError {
            self.compiledLibrary = nil
            self.diagnostics = parseError(error)
        }

        isCompiling = false
    }

    /// Parses Metal compiler error messages into structured diagnostics
    /// - Parameter error: The NSError from makeLibrary
    /// - Returns: An array of CompilationDiagnostic objects
    private func parseError(_ error: NSError) -> [CompilationDiagnostic] {
        let message = error.localizedDescription

        // Metal error format: "program_source:12:5: error: message text"
        // or "program_source:12: error: message text"
        let pattern = #"program_source:(\d+)(?::(\d+))?:\s*(error|warning):\s*(.+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            // Fallback: return a generic diagnostic
            return [CompilationDiagnostic(
                line: 1,
                column: nil,
                severity: .error,
                message: message
            )]
        }

        var diagnostics: [CompilationDiagnostic] = []
        let range = NSRange(message.startIndex..., in: message)

        regex.enumerateMatches(in: message, range: range) { match, _, _ in
            guard let match = match else { return }

            // Extract line number
            guard let lineRange = Range(match.range(at: 1), in: message),
                  let line = Int(message[lineRange]) else { return }

            // Extract column number (optional)
            var column: Int?
            if match.range(at: 2).location != NSNotFound,
               let columnRange = Range(match.range(at: 2), in: message) {
                column = Int(message[columnRange])
            }

            // Extract severity
            guard let severityRange = Range(match.range(at: 3), in: message) else { return }
            let severityStr = String(message[severityRange])
            let severity: DiagnosticSeverity = severityStr.lowercased() == "error" ? .error : .warning

            // Extract message
            guard let messageRange = Range(match.range(at: 4), in: message) else { return }
            let errorMessage = String(message[messageRange])

            diagnostics.append(CompilationDiagnostic(
                line: line,
                column: column,
                severity: severity,
                message: errorMessage
            ))
        }

        // If no diagnostics were parsed, return a generic one
        if diagnostics.isEmpty {
            diagnostics.append(CompilationDiagnostic(
                line: 1,
                column: nil,
                severity: .error,
                message: message
            ))
        }

        return diagnostics
    }

    /// Returns information about the Metal device
    var deviceInfo: String {
        return device.name
    }
}
