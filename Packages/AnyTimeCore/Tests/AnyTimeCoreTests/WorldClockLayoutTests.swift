import CoreGraphics
import XCTest
@testable import AnyTimeCore

final class WorldClockLayoutTests: XCTestCase {
    private let policy = WorldClockLayoutPolicy()

    private let duoOuterDisplay = CGSize(width: 466, height: 678)
    private let duoInnerDisplay = CGSize(width: 669, height: 951)

    func testPhonePortraitUsesSingleColumn() {
        let layout = policy.layout(posture: .unavailable, size: CGSize(width: 393, height: 852))

        XCTAssertEqual(layout, .singleColumn)
    }

    func testDuoOuterDisplayUsesSingleColumn() {
        let layout = policy.layout(posture: .closed, size: duoOuterDisplay)

        XCTAssertEqual(layout, .singleColumn)
    }

    func testDuoInnerDisplayUsesTwoColumns() {
        let layout = policy.layout(posture: .fullyOpen, size: duoInnerDisplay)

        XCTAssertEqual(layout, .twoColumn)
    }

    func testPartiallyOpenHingeSplitsTheContent() {
        let layout = policy.layout(
            posture: .partiallyOpen(angle: .pi / 2),
            size: duoInnerDisplay
        )

        XCTAssertEqual(layout, .hinged(.stacked))
    }

    func testPartiallyOpenHingeWinsOverLargeSize() {
        let layout = policy.layout(
            posture: .partiallyOpen(angle: .pi / 4),
            size: CGSize(width: 1400, height: 1400)
        )

        XCTAssertEqual(layout, .hinged(.stacked))
    }

    func testWideButShortContextStaysSingleColumn() {
        let layout = policy.layout(posture: .unavailable, size: CGSize(width: 852, height: 393))

        XCTAssertEqual(layout, .singleColumn)
    }

    func testTwoColumnThresholdKeepsRoomForBothColumns() {
        let threshold = policy.twoColumnMinimumWidth
        let size = CGSize(width: threshold - 1, height: 900)

        XCTAssertEqual(policy.layout(posture: .fullyOpen, size: size), .singleColumn)
        XCTAssertEqual(
            policy.layout(posture: .fullyOpen, size: CGSize(width: threshold, height: 900)),
            .twoColumn
        )
    }

    func testCalculatorColumnLeavesRoomForTheClockList() {
        let width = policy.calculatorColumnWidth(forAvailableWidth: duoInnerDisplay.width)
        let clockWidth = duoInnerDisplay.width - (policy.horizontalInset * 2) - policy.columnSpacing - width

        XCTAssertGreaterThanOrEqual(width, policy.minimumCalculatorColumnWidth)
        XCTAssertGreaterThanOrEqual(clockWidth, policy.minimumClockColumnWidth)
    }

    func testCalculatorColumnStopsGrowingOnVeryWideDisplays() {
        let width = policy.calculatorColumnWidth(forAvailableWidth: 2000)

        XCTAssertEqual(width, policy.maximumCalculatorColumnWidth)
    }

    func testPartiallyOpenSplitCanBeConfigured() {
        let sideBySidePolicy = WorldClockLayoutPolicy(partiallyOpenSplit: .sideBySide)

        let layout = sideBySidePolicy.layout(
            posture: .partiallyOpen(angle: 1),
            size: duoInnerDisplay
        )

        XCTAssertEqual(layout, .hinged(.sideBySide))
    }

    func testStackedPanesFillTheContentHeightExactly() {
        let policy = WorldClockLayoutPolicy()

        let contentHeight: CGFloat = 900
        let creaseOffset: CGFloat = (1000 / 2) - 100
        let heights = policy.stackedPaneHeights(
            contentHeight: contentHeight,
            creaseOffset: creaseOffset
        )

        XCTAssertEqual(
            heights.top + heights.bottom + policy.hingeGutter,
            contentHeight,
            accuracy: 0.001
        )
    }

    func testStackedPanesCentreTheGutterOnTheCrease() {
        let policy = WorldClockLayoutPolicy()

        let heights = policy.stackedPaneHeights(contentHeight: 900, creaseOffset: 300)
        XCTAssertEqual(heights.top, 300 - (policy.hingeGutter / 2), accuracy: 0.001)
        XCTAssertEqual(heights.bottom, 600 - (policy.hingeGutter / 2), accuracy: 0.001)
        XCTAssertEqual(heights.top + heights.bottom + policy.hingeGutter, 900, accuracy: 0.001)
    }

    func testStackedPanesFallBackToEvenSplitWhenTheCreaseIsTooNearAnEdge() {
        let policy = WorldClockLayoutPolicy()

        let heights = policy.stackedPaneHeights(contentHeight: 900, creaseOffset: 10)

        XCTAssertEqual(heights.top, heights.bottom, accuracy: 0.001)
        XCTAssertEqual(heights.top + heights.bottom + policy.hingeGutter, 900, accuracy: 0.001)
    }

    func testStackedPanesNeverReturnNegativeHeights() {
        let policy = WorldClockLayoutPolicy()

        let heights = policy.stackedPaneHeights(contentHeight: 100, creaseOffset: 400)

        XCTAssertGreaterThanOrEqual(heights.top, 0)
        XCTAssertGreaterThanOrEqual(heights.bottom, 0)
    }

    func testHingeGutterIsPartOfThePolicy() {
        let policy = WorldClockLayoutPolicy()

        XCTAssertGreaterThan(policy.hingeGutter, 0)
        XCTAssertEqual(WorldClockLayoutPolicy(hingeGutter: 40).hingeGutter, 40)
    }

    func testOnlyPartiallyOpenReportsHalfOpen() {
        XCTAssertTrue(DevicePosture.partiallyOpen(angle: 1).isPartiallyOpen)
        XCTAssertFalse(DevicePosture.fullyOpen.isPartiallyOpen)
        XCTAssertFalse(DevicePosture.closed.isPartiallyOpen)
    }
}
