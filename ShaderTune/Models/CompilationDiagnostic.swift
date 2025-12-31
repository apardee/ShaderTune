import Foundation

/// Represents the severity level of a compilation diagnostic
enum DiagnosticSeverity: String, Codable {
    case error
    case warning
    case info
}

/// Represents a single compilation error, warning, or info message
struct CompilationDiagnostic: Identifiable, Equatable {
    let id = UUID()
    let line: Int
    let column: Int?
    let severity: DiagnosticSeverity
    let message: String

    /// A formatted string for display (e.g., "Line 12:5 - error: use of undeclared identifier 'foo'")
    var displayText: String {
        if let column = column {
            return "Line \(line):\(column) - \(severity.rawValue): \(message)"
        } else {
            return "Line \(line) - \(severity.rawValue): \(message)"
        }
    }
}
