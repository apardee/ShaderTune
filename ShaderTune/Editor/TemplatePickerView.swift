import SwiftUI

struct TemplatePickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelectTemplate: (ShaderTemplate) -> Void

    @State private var selectedCategory: ShaderTemplate.TemplateCategory?

    var body: some View {
        NavigationStack {
            List {
                ForEach(ShaderTemplate.TemplateCategory.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(templatesFor(category: category)) { template in
                            TemplateRow(template: template) {
                                onSelectTemplate(template)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shader Templates")
            #if os(macOS)
            .navigationSubtitle("\(ShaderTemplate.allTemplates.count) templates available")
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
    }

    private func templatesFor(category: ShaderTemplate.TemplateCategory) -> [ShaderTemplate] {
        ShaderTemplate.allTemplates.filter { $0.category == category }
    }
}

struct TemplateRow: View {
    let template: ShaderTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TemplatePickerView { template in
        print("Selected: \(template.name)")
    }
}
