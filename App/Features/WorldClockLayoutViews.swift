import AnyTimeCore
import SwiftUI

/// The clock rows are supplied by the caller because they carry the home
/// screen's selection and calendar state.
struct WorldClockLayoutViews<ClockRows: View>: View {
    @Bindable var store: WorldClockStore
    let layout: WorldClockLayout
    let policy: WorldClockLayoutPolicy
    let size: CGSize
    let creaseOffset: CGFloat
    let pullDownMonitor: PullDownMonitor
    @ViewBuilder let clockRows: () -> ClockRows

    var body: some View {
        switch layout {
        case .singleColumn:
            singleColumn
        case .twoColumn:
            twoColumn
        case let .hinged(split):
            hinged(split: split)
        }
    }

    private var singleColumn: some View {
        let list = List {
            Section {
                ReferenceCalculatorCard(store: store)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                clockRows()
            }
        }

        return list.listChrome().observeScrollOffset(into: pullDownMonitor)
    }

    /// The calculator column stays put while the clock list scrolls, so nudging
    /// the reference time updates the clocks without scrolling away from them.
    private var twoColumn: some View {
        HStack(alignment: .top, spacing: policy.columnSpacing) {
            calculatorPane
                .frame(width: policy.calculatorColumnWidth(forAvailableWidth: size.width))

            clockListPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, policy.horizontalInset)
    }

    @ViewBuilder
    private func hinged(split: WorldClockHingeSplit) -> some View {
        switch split {
        case .stacked:
            let heights = policy.stackedPaneHeights(
                contentHeight: size.height,
                creaseOffset: creaseOffset
            )

            VStack(spacing: 0) {
                calculatorPane
                    .frame(height: heights.top)

                gutter(height: policy.hingeGutter)

                clockListPane
                    .frame(height: heights.bottom)
            }
            .padding(.horizontal, policy.horizontalInset)
        case .sideBySide:
            HStack(spacing: 0) {
                calculatorPane
                    .frame(maxWidth: .infinity)

                gutter(width: policy.hingeGutter)

                clockListPane
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, policy.horizontalInset)
        }
    }

    private var calculatorPane: some View {
        ScrollView {
            ReferenceCalculatorCard(store: store)
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var clockListPane: some View {
        let list = List {
            Section {
                clockRows()
            }
        }

        return list.listChrome().observeScrollOffset(into: pullDownMonitor)
    }

    private func gutter(height: CGFloat = 0, width: CGFloat = 0) -> some View {
        Color.clear
            .frame(height: height)
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

private extension List {
    func listChrome() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}
