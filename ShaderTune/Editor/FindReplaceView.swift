import SwiftUI

struct FindReplaceView: View {
    @Binding var searchText: String
    @Binding var replaceText: String
    @Binding var isVisible: Bool

    let onFind: () -> Void
    let onReplace: () -> Void
    let onReplaceAll: () -> Void

    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Find", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($searchFieldFocused)
                        .onSubmit {
                            onFind()
                        }
                }
                .padding(6)
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(6)

                Button(action: onFind) {
                    Image(systemName: "arrow.down.circle")
                }
                .help("Find Next")

                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            HStack(spacing: 8) {
                // Replace field
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.secondary)
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            onReplace()
                        }
                }
                .padding(6)
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(6)

                Button("Replace") {
                    onReplace()
                }
                .buttonStyle(.bordered)

                Button("All") {
                    onReplaceAll()
                }
                .buttonStyle(.bordered)
                .help("Replace All")
            }
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .onAppear {
            searchFieldFocused = true
        }
    }
}

#Preview {
    @Previewable @State var searchText = "float4"
    @Previewable @State var replaceText = "float3"
    @Previewable @State var isVisible = true

    FindReplaceView(
        searchText: $searchText,
        replaceText: $replaceText,
        isVisible: $isVisible,
        onFind: { print("Find") },
        onReplace: { print("Replace") },
        onReplaceAll: { print("Replace All") }
    )
    .frame(width: 400)
}
