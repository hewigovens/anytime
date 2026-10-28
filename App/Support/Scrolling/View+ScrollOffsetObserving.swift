import SwiftUI

extension View {
    /// Uses `onScrollGeometryChange` where it is available and falls back to the
    /// platform scroll view observer on older systems.
    @ViewBuilder
    func observeScrollOffset(into monitor: PullDownMonitor) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            }, action: { _, newValue in
                monitor.contentOffset = newValue
            })
        } else {
            background {
                ScrollViewOffsetObserver { offset in
                    monitor.contentOffset = offset
                }
            }
        }
    }
}
