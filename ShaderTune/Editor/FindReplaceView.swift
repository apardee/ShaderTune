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
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Find", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($searchFieldFocused)
                        .onSubmit {
                            onFind()
                        }
                }
                .padding(5)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))

                Button(action: onFind) {
                    Image(systemName: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .help("Find Next")

                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            HStack(spacing: 6) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            onReplace()
                        }
                }
                .padding(5)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))

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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .top
        )
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
