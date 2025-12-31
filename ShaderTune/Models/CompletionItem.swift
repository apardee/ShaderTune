import Foundation

/// Represents a single code completion item
struct CompletionItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let kind: CompletionKind
    let description: String
    let snippet: String?

    init(text: String, kind: CompletionKind, description: String, snippet: String? = nil) {
        self.text = text
        self.kind = kind
        self.description = description
        self.snippet = snippet
    }

    /// The text to insert when this completion is selected
    var insertionText: String {
        return snippet ?? text
    }
}

/// The kind of completion item
enum CompletionKind: String {
    case keyword
    case type
    case function
    case attribute
    case variable

    var iconName: String {
        switch self {
        case .keyword:
            return "key.fill"
        case .type:
            return "cube.fill"
        case .function:
            return "function"
        case .attribute:
            return "at"
        case .variable:
            return "v.circle.fill"
        }
    }

    var displayName: String {
        return rawValue.capitalized
    }
}
