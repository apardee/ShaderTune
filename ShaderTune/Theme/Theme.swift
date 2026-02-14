import SwiftUI

/// Ableton-style flat UI theme constants
enum AppTheme {
    // MARK: - Colors

    static let bg = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255)
    static let bgLight = Color(red: 0x2A / 255, green: 0x2A / 255, blue: 0x2A / 255)
    static let bgLighter = Color(red: 0x3D / 255, green: 0x3D / 255, blue: 0x3D / 255)
    static let surface = Color(red: 0x33 / 255, green: 0x33 / 255, blue: 0x33 / 255)
    static let border = Color(red: 0x4A / 255, green: 0x4A / 255, blue: 0x4A / 255)
    static let textPrimary = Color(red: 0xCC / 255, green: 0xCC / 255, blue: 0xCC / 255)
    static let textSecondary = Color(red: 0x99 / 255, green: 0x99 / 255, blue: 0x99 / 255)
    static let accent = Color.orange
    static let selection = Color.orange.opacity(0.3)

    // MARK: - Layout

    static let cornerRadius: CGFloat = 2
    static let borderWidth: CGFloat = 1
}

/// Flat panel modifier — dark bg, thin border, no shadow
struct FlatPanel: ViewModifier {
    var background: Color = AppTheme.bgLight

    func body(content: Content) -> some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.border, lineWidth: AppTheme.borderWidth)
            )
    }
}

extension View {
    func flatPanel(background: Color = AppTheme.bgLight) -> some View {
        modifier(FlatPanel(background: background))
    }
}

/// Flat button style matching Ableton aesthetic
struct FlatButtonStyle: ButtonStyle {
    var isPrimary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isPrimary ? .black : AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                isPrimary
                    ? (configuration.isPressed ? AppTheme.accent.opacity(0.8) : AppTheme.accent)
                    : (configuration.isPressed ? AppTheme.bgLighter : AppTheme.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isPrimary ? Color.clear : AppTheme.border,
                        lineWidth: AppTheme.borderWidth
                    )
            )
    }
}

extension ButtonStyle where Self == FlatButtonStyle {
    static var flat: FlatButtonStyle { FlatButtonStyle() }
    static var flatPrimary: FlatButtonStyle { FlatButtonStyle(isPrimary: true) }
}
