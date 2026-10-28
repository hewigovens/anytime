import SwiftUI

extension View {
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
