import CoreGraphics

public enum WorldClockLayout: Equatable, Sendable {
    case singleColumn
    case hinged(WorldClockHingeSplit)
    case twoColumn
}

public enum WorldClockHingeSplit: Equatable, Sendable {
    case stacked
    case sideBySide
}

public struct WorldClockLayoutPolicy: Equatable, Sendable {
    public var minimumCalculatorColumnWidth: CGFloat
    public var minimumClockColumnWidth: CGFloat
    public var maximumCalculatorColumnWidth: CGFloat
    public var columnSpacing: CGFloat
    public var horizontalInset: CGFloat
    public var twoColumnMinimumHeight: CGFloat
    // Hinge angle does not identify the fold axis, so use a configured split.
    public var partiallyOpenSplit: WorldClockHingeSplit
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

    public var twoColumnMinimumWidth: CGFloat {
        minimumCalculatorColumnWidth + minimumClockColumnWidth + columnSpacing + (horizontalInset * 2)
    }

    public func layout(posture: DevicePosture, size: CGSize) -> WorldClockLayout {
        if posture.isPartiallyOpen {
            return .hinged(partiallyOpenSplit)
        }

        if size.width >= twoColumnMinimumWidth, size.height >= twoColumnMinimumHeight {
            return .twoColumn
        }

        return .singleColumn
    }

    public func calculatorColumnWidth(forAvailableWidth availableWidth: CGFloat) -> CGFloat {
        let contentWidth = max(0, availableWidth - (horizontalInset * 2))
        let clockShareCeiling = contentWidth - columnSpacing - minimumClockColumnWidth
        return max(minimumCalculatorColumnWidth, min(maximumCalculatorColumnWidth, clockShareCeiling))
    }

    /// `creaseOffset` is measured from the content top, below the header.
    public func stackedPaneHeights(
        contentHeight: CGFloat,
        creaseOffset: CGFloat,
        minimumPaneHeight: CGFloat = 180
    ) -> (top: CGFloat, bottom: CGFloat) {
        let top = creaseOffset - (hingeGutter / 2)
        let bottom = contentHeight - creaseOffset - (hingeGutter / 2)

        guard top >= minimumPaneHeight, bottom >= minimumPaneHeight else {
            let paneHeight = max(0, (contentHeight - hingeGutter) / 2)
            return (top: paneHeight, bottom: paneHeight)
        }

        return (top: top, bottom: bottom)
    }
}
