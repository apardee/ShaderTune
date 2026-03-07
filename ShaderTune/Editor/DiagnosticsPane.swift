//
//  DiagnosticsPane.swift
//  ShaderTune
//
//  Xcode-style bottom pane for displaying compiler errors and warnings
//

import SwiftUI

struct DiagnosticsPane: View {
    let diagnostics: [CompilationDiagnostic]
    let onDismiss: () -> Void
    let onSelectDiagnostic: ((CompilationDiagnostic) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: diagnosticIcon)
                    .foregroundColor(diagnosticColor)
                    .font(.system(size: 14))

                Text(diagnosticTitle)
                    .font(.system(size: 12, weight: .medium))

                Text("(\(diagnostics.count))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Hide diagnostics")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.separator),
                alignment: .bottom
            )

            // Diagnostics list
            if diagnostics.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.green.opacity(0.6))
                    Text("No Issues")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(diagnostics) { diagnostic in
                            DiagnosticRow(
                                diagnostic: diagnostic,
                                onSelect: {
                                    onSelectDiagnostic?(diagnostic)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var diagnosticIcon: String {
        let errorCount = diagnostics.filter { $0.severity == .error }.count
        if errorCount > 0 {
            return "xmark.octagon.fill"
        } else if !diagnostics.isEmpty {
            return "exclamationmark.triangle.fill"
        }
        return "checkmark.circle.fill"
    }

    private var diagnosticColor: Color {
        let errorCount = diagnostics.filter { $0.severity == .error }.count
        if errorCount > 0 {
            return .red
        } else if !diagnostics.isEmpty {
            return .yellow
        }
        return .green
    }

    private var diagnosticTitle: String {
        let errorCount = diagnostics.filter { $0.severity == .error }.count
        let warningCount = diagnostics.filter { $0.severity == .warning }.count

        if errorCount > 0 {
            return errorCount == 1 ? "1 Error" : "\(errorCount) Errors"
        } else if warningCount > 0 {
            return warningCount == 1 ? "1 Warning" : "\(warningCount) Warnings"
        }
        return "No Issues"
    }
}

struct DiagnosticRow: View {
    let diagnostic: CompilationDiagnostic
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 8) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                    .frame(width: 16)

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    // File location and line
                    HStack(spacing: 4) {
                        if let column = diagnostic.column {
                            Text("Line \(diagnostic.line):\(column)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Line \(diagnostic.line)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        Text(diagnostic.severity.rawValue.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(iconColor)
                    }

                    // Message
                    Text(diagnostic.message)
                        .font(.system(size: 12))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.separator.opacity(0.5)),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var iconName: String {
        switch diagnostic.severity {
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch diagnostic.severity {
        case .error:
            return .red
        case .warning:
            return .yellow
        case .info:
            return .blue
        }
    }
}

#Preview {
    DiagnosticsPane(
        diagnostics: [
            CompilationDiagnostic(
                line: 12,
                column: 5,
                severity: .error,
                message: "use of undeclared identifier 'foo'"
            ),
            CompilationDiagnostic(
                line: 24,
                column: nil,
                severity: .warning,
                message: "unused variable 'bar'"
            ),
        ],
        onDismiss: {},
        onSelectDiagnostic: nil
    )
    .frame(height: 200)
}
