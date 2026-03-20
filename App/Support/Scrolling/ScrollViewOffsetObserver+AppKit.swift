import SwiftUI

#if canImport(AppKit)
import AppKit

struct ScrollViewOffsetObserver: NSViewRepresentable {
    let onOffsetChange: (CGFloat) -> Void

    func makeNSView(context: Context) -> OffsetObservationView {
        let view = OffsetObservationView()
        view.onOffsetChange = onOffsetChange
        return view
    }

    func updateNSView(_ nsView: OffsetObservationView, context: Context) {
        nsView.onOffsetChange = onOffsetChange
        nsView.attachIfNeeded()
    }
}

extension ScrollViewOffsetObserver {
    final class OffsetObservationView: NSView {
        var onOffsetChange: ((CGFloat) -> Void)?

        private weak var observedScrollView: NSScrollView?
        private weak var observedClipView: NSClipView?
        private var hasScheduledRetry = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            attachIfNeeded()
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            attachIfNeeded()
        }

        func attachIfNeeded() {
            guard let scrollView = enclosingScrollView() else {
                scheduleRetry()
                return
            }

            hasScheduledRetry = false

            guard observedScrollView !== scrollView else {
                return
            }

            if let observedClipView {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSView.boundsDidChangeNotification,
                    object: observedClipView
                )
            }

            observedScrollView = scrollView
            observedClipView = scrollView.contentView
            scrollView.contentView.postsBoundsChangedNotifications = true

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(boundsDidChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )

            onOffsetChange?(scrollView.documentVisibleRect.minY)
        }

        private func scheduleRetry() {
            guard hasScheduledRetry == false else {
                return
            }

            hasScheduledRetry = true
            DispatchQueue.main.async { [weak self] in
                self?.attachIfNeeded()
            }
        }

        private func enclosingScrollView() -> NSScrollView? {
            sequence(first: superview, next: { $0?.superview })
                .first(where: { $0 is NSScrollView }) as? NSScrollView
        }

        @objc
        private func boundsDidChange(_ notification: Notification) {
            guard let observedScrollView else {
                return
            }

            onOffsetChange?(observedScrollView.documentVisibleRect.minY)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
#endif
