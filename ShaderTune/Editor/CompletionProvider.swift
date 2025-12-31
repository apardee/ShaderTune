import Foundation

/// Provides code completion suggestions based on source code context
class CompletionProvider {

    private let database = MetalKeywordDatabase.allCompletions

    /// Get completion suggestions for the given source code and cursor position
    /// - Parameters:
    ///   - source: The full source code
    ///   - cursorPosition: The cursor position as String.Index
    /// - Returns: Array of filtered completion items
    func completions(for source: String, at cursorPosition: String.Index) -> [CompletionItem] {
        // Get the partial word being typed
        guard let partialWord = extractPartialWord(from: source, at: cursorPosition) else {
            return []
        }

        // Don't show completions for very short prefixes
        guard partialWord.count >= 2 else {
            return []
        }

        // Filter completions that match the partial word
        return database.filter { completion in
            completion.text.lowercased().hasPrefix(partialWord.lowercased())
        }
        .sorted { $0.text < $1.text }
    }

    /// Extract the partial word being typed at the cursor position
    /// - Parameters:
    ///   - source: The source code
    ///   - cursorPosition: The cursor position
    /// - Returns: The partial word or nil if no word is being typed
    private func extractPartialWord(from source: String, at cursorPosition: String.Index) -> String? {
        guard cursorPosition <= source.endIndex else { return nil }

        // Find the start of the current word by going backwards from cursor
        var startIndex = cursorPosition

        // Move back while we're in a word character
        while startIndex > source.startIndex {
            let prevIndex = source.index(before: startIndex)
            let char = source[prevIndex]

            // Word characters: letters, digits, underscore
            if char.isLetter || char.isNumber || char == "_" {
                startIndex = prevIndex
            } else {
                break
            }
        }

        // If we haven't moved back, no word is being typed
        guard startIndex < cursorPosition else {
            return nil
        }

        // Extract the partial word
        let partialWord = String(source[startIndex..<cursorPosition])

        // Don't complete if it's just numbers
        guard partialWord.contains(where: { $0.isLetter || $0 == "_" }) else {
            return nil
        }

        return partialWord
    }

    /// Check if completion should be triggered at the current cursor position
    /// - Parameters:
    ///   - source: The source code
    ///   - cursorPosition: The cursor position
    /// - Returns: True if completion should be triggered
    func shouldTriggerCompletion(for source: String, at cursorPosition: String.Index) -> Bool {
        guard let partialWord = extractPartialWord(from: source, at: cursorPosition) else {
            return false
        }

        // Trigger if we have at least 2 characters
        return partialWord.count >= 2
    }

    /// Get the range of the current word being completed
    /// - Parameters:
    ///   - source: The source code
    ///   - cursorPosition: The cursor position
    /// - Returns: The range of the word, or nil
    func wordRange(in source: String, at cursorPosition: String.Index) -> Range<String.Index>? {
        guard cursorPosition <= source.endIndex else { return nil }

        // Find start of word
        var startIndex = cursorPosition
        while startIndex > source.startIndex {
            let prevIndex = source.index(before: startIndex)
            let char = source[prevIndex]
            if char.isLetter || char.isNumber || char == "_" {
                startIndex = prevIndex
            } else {
                break
            }
        }

        // Find end of word (if cursor is in middle of word)
        var endIndex = cursorPosition
        while endIndex < source.endIndex {
            let char = source[endIndex]
            if char.isLetter || char.isNumber || char == "_" {
                endIndex = source.index(after: endIndex)
            } else {
                break
            }
        }

        guard startIndex < endIndex else {
            return nil
        }

        return startIndex..<endIndex
    }
}
