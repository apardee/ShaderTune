import SwiftUI

struct CompletionView: View {
    let completions: [CompletionItem]
    let onSelect: (CompletionItem) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if completions.isEmpty {
                Text("No completions")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(completions.enumerated()), id: \.element.id) {
                                index, item in
                                CompletionRow(
                                    item: item,
                                    isSelected: index == selectedIndex
                                )
                                .id(item.id)
                                .onTapGesture {
                                    onSelect(item)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .onChange(of: selectedIndex) { _, newValue in
                        if completions.indices.contains(newValue) {
                            withAnimation {
                                proxy.scrollTo(completions[newValue].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 400)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator))
        .shadow(radius: 8, y: 2)
        #if os(macOS)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            if completions.indices.contains(selectedIndex) {
                onSelect(completions[selectedIndex])
            }
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onKeyPress(.tab) {
            if completions.indices.contains(selectedIndex) {
                onSelect(completions[selectedIndex])
            }
            return .handled
        }
        #endif
    }

    private func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        if completions.indices.contains(newIndex) {
            selectedIndex = newIndex
        }
    }
}

struct CompletionRow: View {
    let item: CompletionItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.kind.iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Kind badge
            Text(item.kind.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(iconColor.opacity(0.15))
                .foregroundColor(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }

    private var iconColor: Color {
        switch item.kind {
        case .keyword:
            return .purple
        case .type:
            return .blue
        case .function:
            return .green
        case .attribute:
            return .orange
        case .variable:
            return .cyan
        }
    }
}

#Preview("With Completions") {
    CompletionView(
        completions: [
            CompletionItem(text: "float4", kind: .type, description: "4-component float vector"),
            CompletionItem(
                text: "fragment", kind: .keyword, description: "Fragment shader function qualifier"),
            CompletionItem(
                text: "fma", kind: .function, description: "Fused multiply-add",
                snippet: "fma($0, $1, $2)"),
        ],
        onSelect: { item in
            print("Selected: \(item.text)")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}

#Preview("Empty") {
    CompletionView(
        completions: [],
        onSelect: { _ in },
        onDismiss: {}
    )
}
