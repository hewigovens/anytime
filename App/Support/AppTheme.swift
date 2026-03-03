import SwiftUI

#if canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#endif

enum AppTheme {
    static let backgroundTop = dynamicColor(
        light: PlatformColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1),
        dark: PlatformColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1)
    )
    static let backgroundMiddle = dynamicColor(
        light: PlatformColor(red: 0.90, green: 0.93, blue: 0.96, alpha: 1),
        dark: PlatformColor(red: 0.05, green: 0.09, blue: 0.12, alpha: 1)
    )
    static let backgroundBottom = dynamicColor(
        light: PlatformColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 1),
        dark: PlatformColor(red: 0.04, green: 0.08, blue: 0.11, alpha: 1)
    )
    static let accent = dynamicColor(
        light: PlatformColor(red: 0.12, green: 0.57, blue: 0.64, alpha: 1),
        dark: PlatformColor(red: 0.38, green: 0.80, blue: 0.86, alpha: 1)
    )
    static let actionBlue = dynamicColor(
        light: PlatformColor(red: 0.03, green: 0.45, blue: 0.69, alpha: 1),
        dark: PlatformColor(red: 0.10, green: 0.49, blue: 0.78, alpha: 1)
    )
    static let magic = dynamicColor(
        light: PlatformColor(red: 0.08, green: 0.48, blue: 0.57, alpha: 1),
        dark: PlatformColor(red: 0.15, green: 0.59, blue: 0.69, alpha: 1)
    )
    static let warm = dynamicColor(
        light: PlatformColor(red: 0.94, green: 0.62, blue: 0.24, alpha: 1),
        dark: PlatformColor(red: 0.97, green: 0.69, blue: 0.31, alpha: 1)
    )
    static let ink = dynamicColor(
        light: PlatformColor(red: 0.11, green: 0.17, blue: 0.23, alpha: 1),
        dark: PlatformColor(red: 0.94, green: 0.97, blue: 0.99, alpha: 1)
    )
    static let warmInk = Color(red: 0.14, green: 0.10, blue: 0.08)
    static let calculatorSurfaceTop = dynamicColor(
        light: PlatformColor(red: 0.98, green: 0.99, blue: 1.00, alpha: 0.92),
        dark: PlatformColor(red: 0.11, green: 0.15, blue: 0.19, alpha: 0.96)
    )
    static let calculatorSurfaceBottom = dynamicColor(
        light: PlatformColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 0.90),
        dark: PlatformColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 0.94)
    )
    static let clockSurfaceTop = dynamicColor(
        light: PlatformColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 0.78),
        dark: PlatformColor(red: 0.10, green: 0.14, blue: 0.18, alpha: 0.91)
    )
    static let clockSurfaceBottom = dynamicColor(
        light: PlatformColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 0.76),
        dark: PlatformColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 0.89)
    )
    static let calculatorStroke = dynamicColor(
        light: PlatformColor(red: 0.82, green: 0.87, blue: 0.92, alpha: 0.95),
        dark: PlatformColor(white: 1, alpha: 0.15)
    )
    static let cardStroke = dynamicColor(
        light: PlatformColor(red: 0.84, green: 0.88, blue: 0.93, alpha: 0.82),
        dark: PlatformColor(white: 1, alpha: 0.10)
    )
    static let searchFieldStroke = dynamicColor(
        light: PlatformColor(red: 0.83, green: 0.87, blue: 0.91, alpha: 0.88),
        dark: PlatformColor(white: 1, alpha: 0.12)
    )
    static let headerSurface = dynamicColor(
        light: PlatformColor(red: 0.93, green: 0.95, blue: 0.97, alpha: 1),
        dark: PlatformColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1)
    )
    static let searchFieldSurface = dynamicColor(
        light: PlatformColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 0.94),
        dark: PlatformColor(red: 0.10, green: 0.13, blue: 0.17, alpha: 0.94)
    )
    static let panelTop = dynamicColor(
        light: PlatformColor(white: 1, alpha: 0.98),
        dark: PlatformColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 0.98)
    )
    static let panelBottom = dynamicColor(
        light: PlatformColor(white: 1, alpha: 0.82),
        dark: PlatformColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 0.94)
    )
    static let panelDivider = dynamicColor(
        light: PlatformColor(white: 1, alpha: 0.8),
        dark: PlatformColor(white: 1, alpha: 0.08)
    )
    static let shadow = dynamicColor(
        light: PlatformColor(red: 0.11, green: 0.17, blue: 0.23, alpha: 0.05),
        dark: PlatformColor(red: 0, green: 0, blue: 0, alpha: 0.28)
    )

    static let background = LinearGradient(
        colors: [
            backgroundTop,
            backgroundMiddle,
            backgroundBottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let calculatorSurface = LinearGradient(
        colors: [
            calculatorSurfaceTop,
            calculatorSurfaceBottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let clockSurface = LinearGradient(
        colors: [
            clockSurfaceTop,
            clockSurfaceBottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private static func dynamicColor(light: PlatformColor, dark: PlatformColor) -> Color {
        #if canImport(AppKit)
        let color = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
        return Color(nsColor: color)
        #elseif canImport(UIKit)
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
        return Color(uiColor: color)
        #endif
    }
}
