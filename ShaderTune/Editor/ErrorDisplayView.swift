import SwiftUI

struct ErrorDisplayView: View {
    let diagnostics: [CompilationDiagnostic]

    var body: some View {
        if diagnostics.isEmpty {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Compilation successful")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(diagnostics) { diagnostic in
                        DiagnosticRow(diagnostic: diagnostic)
                    }
                }
                .padding()
            }
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
            #else
            .background(Color(.systemBackground))
            #endif
        }
    }
}

struct DiagnosticRow: View {
    let diagnostic: CompilationDiagnostic

    var iconName: String {
        switch diagnostic.severity {
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch diagnostic.severity {
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Line \(diagnostic.line)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)

                    if let column = diagnostic.column {
                        Text(":\(column)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(diagnostic.severity.rawValue.uppercased())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(iconColor)
                }

                Text(diagnostic.message)
                    .font(.system(.body, design: .default))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(6)
    }
}

#Preview("Success") {
    ErrorDisplayView(diagnostics: [])
        .frame(height: 200)
}

#Preview("With Errors") {
    ErrorDisplayView(diagnostics: [
        CompilationDiagnostic(
            line: 12,
            column: 5,
            severity: .error,
            message: "use of undeclared identifier 'foo'"
        ),
        CompilationDiagnostic(
            line: 18,
            column: nil,
            severity: .warning,
            message: "unused variable 'bar'"
        ),
        CompilationDiagnostic(
            line: 25,
            column: 10,
            severity: .error,
            message: "expected ';' after expression"
        )
    ])
    .frame(height: 200)
}
