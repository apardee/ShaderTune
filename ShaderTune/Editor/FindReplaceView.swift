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
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Find", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(AppTheme.textPrimary)
                        .focused($searchFieldFocused)
                        .onSubmit {
                            onFind()
                        }
                }
                .padding(5)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.border, lineWidth: AppTheme.borderWidth)
                )

                Button(action: onFind) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(AppTheme.textPrimary)
                }
                .buttonStyle(.flat)
                .help("Find Next")

                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            HStack(spacing: 6) {
                // Replace field
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                        .foregroundColor(AppTheme.textPrimary)
                        .onSubmit {
                            onReplace()
                        }
                }
                .padding(5)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.border, lineWidth: AppTheme.borderWidth)
                )

                Button("Replace") {
                    onReplace()
                }
                .buttonStyle(.flat)

                Button("All") {
                    onReplaceAll()
                }
                .buttonStyle(.flat)
                .help("Replace All")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.bgLight)
        .overlay(
            Rectangle()
                .frame(height: AppTheme.borderWidth)
                .foregroundColor(AppTheme.border),
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
