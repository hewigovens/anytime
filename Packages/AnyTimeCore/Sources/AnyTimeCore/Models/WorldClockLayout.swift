import CoreGraphics
import Foundation

/// How the home screen arranges the reference calculator and the clock list.
public enum WorldClockLayout: Equatable, Sendable {
    /// A single scrolling column, used on phones and other narrow contexts.
    case singleColumn
    /// The content is divided across a foldable device's hinge.
    case hinged(WorldClockHingeSplit)
    /// Two columns side by side, used when the display is large enough to show
    /// the reference calculator and the clocks at the same time.
    case twoColumn
}

/// Which way the two panes sit relative to a device hinge.
public enum WorldClockHingeSplit: Equatable, Sendable {
    /// The panes sit above and below each other.
    ///
    /// This suits the calculator-over-clocks reading order and works whether the
    /// device rests in a laptop or a book posture.
    case stacked
    /// The panes sit left and right of each other.
    case sideBySide
}

/// Chooses a ``WorldClockLayout`` for the current posture and available space.
///
/// The policy is deliberately free of SwiftUI and UIKit so layout decisions can
/// be unit tested away from a device.
public struct WorldClockLayoutPolicy: Equatable, Sendable {
    /// The narrowest the pinned calculator column may become.
    public var minimumCalculatorColumnWidth: CGFloat
    /// The narrowest the clock list may become before a second column stops
    /// being worthwhile.
    public var minimumClockColumnWidth: CGFloat
    /// The widest the pinned calculator column may become.
    public var maximumCalculatorColumnWidth: CGFloat
    /// The gap between the two columns.
    public var columnSpacing: CGFloat
    /// The horizontal inset around the content.
    public var horizontalInset: CGFloat
    /// The minimum height before two columns are preferred.
    ///
    /// The height floor keeps short, wide contexts such as a phone in landscape
    /// on the single column layout, where the tall calculator card still fits.
    public var twoColumnMinimumHeight: CGFloat
    /// The split used while the hinge is partially open.
    ///
    /// A hinge angle does not reveal whether the device is resting in a laptop
    /// or a book posture, so the split is fixed rather than guessed.
    public var partiallyOpenSplit: WorldClockHingeSplit
    /// The clearance kept either side of a hinge so content avoids the crease.
    public var hingeGutter: CGFloat

    public init(
        minimumCalculatorColumnWidth: CGFloat = 260,
        minimumClockColumnWidth: CGFloat = 340,
        maximumCalculatorColumnWidth: CGFloat = 400,
        columnSpacing: CGFloat = 20,
        horizontalInset: CGFloat = 20,
        twoColumnMinimumHeight: CGFloat = 560,
        partiallyOpenSplit: WorldClockHingeSplit = .stacked,
        hingeGutter: CGFloat = 28
    ) {
        self.minimumCalculatorColumnWidth = minimumCalculatorColumnWidth
        self.minimumClockColumnWidth = minimumClockColumnWidth
        self.maximumCalculatorColumnWidth = maximumCalculatorColumnWidth
        self.columnSpacing = columnSpacing
        self.horizontalInset = horizontalInset
        self.twoColumnMinimumHeight = twoColumnMinimumHeight
        self.partiallyOpenSplit = partiallyOpenSplit
        self.hingeGutter = hingeGutter
    }

    /// The width at which two columns start to be worthwhile.
    ///
    /// Derived from the two minimum column widths so the threshold cannot drift
    /// away from the widths it is meant to protect.
    public var twoColumnMinimumWidth: CGFloat {
        minimumCalculatorColumnWidth + minimumClockColumnWidth + columnSpacing + (horizontalInset * 2)
    }

    /// The layout to use for a posture and size.
    ///
    /// A partially open hinge always wins: the panes are split across the hinge
    /// so the content stays readable while the device rests half folded. When the
    /// hinge is fully open or unavailable, the decision falls back to the size.
    ///
    /// - Parameters:
    ///   - posture: The current hinge posture, or ``DevicePosture/unavailable``.
    ///   - size: The space available to the home screen content.
    public func layout(posture: DevicePosture, size: CGSize) -> WorldClockLayout {
        if posture.isPartiallyOpen {
            return .hinged(partiallyOpenSplit)
        }

        if size.width >= twoColumnMinimumWidth, size.height >= twoColumnMinimumHeight {
            return .twoColumn
        }

        return .singleColumn
    }

    /// The width for the pinned calculator column in the two column layout.
    ///
    /// The calculator column takes a comfortable share of the width, but the
    /// clock list keeps at least ``minimumClockColumnWidth`` so the two panes
    /// stay balanced.
    public func calculatorColumnWidth(forAvailableWidth availableWidth: CGFloat) -> CGFloat {
        let contentWidth = max(0, availableWidth - (horizontalInset * 2))
        let clockShareCeiling = contentWidth - columnSpacing - minimumClockColumnWidth
        return max(minimumCalculatorColumnWidth, min(maximumCalculatorColumnWidth, clockShareCeiling))
    }
}
