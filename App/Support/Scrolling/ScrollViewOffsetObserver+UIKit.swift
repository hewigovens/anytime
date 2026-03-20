import SwiftUI

#if canImport(UIKit)
import UIKit

struct ScrollViewOffsetObserver: UIViewRepresentable {
    let onOffsetChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> OffsetObservationView {
        let view = OffsetObservationView()
        view.onOffsetChange = onOffsetChange
        return view
    }

    func updateUIView(_ uiView: OffsetObservationView, context: Context) {
        uiView.onOffsetChange = onOffsetChange
        uiView.attachIfNeeded()
    }
}

extension ScrollViewOffsetObserver {
    final class OffsetObservationView: UIView {
        var onOffsetChange: ((CGFloat) -> Void)?

        private weak var observedScrollView: UIScrollView?
        private var observation: NSKeyValueObservation?
        private var hasScheduledRetry = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            attachIfNeeded()
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
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

            observation?.invalidate()
            observedScrollView = scrollView
            observation = scrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] scrollView, _ in
                Task { @MainActor in
                    let normalizedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                    self?.onOffsetChange?(normalizedOffset)
                }
            }
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

        private func enclosingScrollView() -> UIScrollView? {
            sequence(first: superview, next: { $0?.superview })
                .first(where: { $0 is UIScrollView }) as? UIScrollView
        }

        deinit {
            observation?.invalidate()
        }
    }
}
#endif
