import SwiftUI

struct QuickActionButtonStyle: ButtonStyle {
    let role: QuickActionRole

    func makeBody(configuration: Configuration) -> some View {
        let fill = fillColor
        let foreground = foregroundColor

        return configuration.label
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(fill.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(role == .warm ? 0.28 : 0.18), lineWidth: 1)
            }
            .shadow(
                color: fill.opacity(configuration.isPressed ? 0.08 : 0.24),
                radius: configuration.isPressed ? 6 : 10,
                y: configuration.isPressed ? 2 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }

    private var fillColor: Color {
        switch role {
        case .cool:
            AppTheme.actionBlue
        case .warm:
            AppTheme.warm
        case .magic:
            AppTheme.magic
        }
    }

    private var foregroundColor: Color {
        switch role {
        case .cool, .magic:
            .white
        case .warm:
            AppTheme.warmInk
        }
    }
}
