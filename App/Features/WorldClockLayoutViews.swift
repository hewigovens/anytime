import AnyTimeCore
import SwiftUI

/// Renders the home screen content for a chosen ``WorldClockLayout``.
///
/// The clock rows are supplied by the caller because they carry the home
/// screen's selection and calendar state.
struct WorldClockLayoutViews<ClockRows: View>: View {
    @Bindable var store: WorldClockStore
    let layout: WorldClockLayout
    let policy: WorldClockLayoutPolicy
    let size: CGSize
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

    /// The reference calculator and clocks in one scrolling column.
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

    /// The reference calculator and the clock list side by side.
    ///
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

    /// The content split across a half-folded device's hinge.
    ///
    /// The calculator sits in one pane and the clocks in the other, with a
    /// gutter so neither pane is hidden by the crease.
    @ViewBuilder
    private func hinged(split: WorldClockHingeSplit) -> some View {
        switch split {
        case .stacked:
            VStack(spacing: 0) {
                calculatorPane
                    .frame(maxHeight: .infinity)

                gutter(height: policy.hingeGutter)

                clockListPane
                    .frame(maxHeight: .infinity)
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

    /// An invisible spacer standing in for the crease of a folded display.
    private func gutter(height: CGFloat = 0, width: CGFloat = 0) -> some View {
        Color.clear
            .frame(height: height)
            .frame(width: width)
            .accessibilityHidden(true)
    }
}

private extension List {
    /// Applies the transparent list styling shared by every layout.
    func listChrome() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
    }
}
