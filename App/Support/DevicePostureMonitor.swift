import AnyTimeCore
import SwiftUI

/// `UIHingeInteraction` only reports through an interaction attached to a view,
/// so the monitor is driven by ``HingePostureReader``.
@MainActor
@Observable
final class DevicePostureMonitor {
    private(set) var posture: DevicePosture

    init() {
        posture = DevicePostureOverride.current ?? .unavailable
    }

    func update(_ posture: DevicePosture) {
        // An override pins the posture so the foldable layouts stay previewable
        // on devices and simulators that cannot fold.
        guard DevicePostureOverride.current == nil, posture != self.posture else {
            return
        }

        self.posture = posture
    }
}

#if canImport(UIKit)
import UIKit

/// Reports hinge changes from the view hierarchy to a ``DevicePostureMonitor``.
struct HingePostureReader: UIViewRepresentable {
    let monitor: DevicePostureMonitor

    func makeUIView(context: Context) -> HingeObservingView {
        let view = HingeObservingView()
        view.monitor = monitor
        return view
    }

    func updateUIView(_ uiView: HingeObservingView, context: Context) {
        uiView.monitor = monitor
    }
}

/// Owns a hinge interaction for the view's lifetime.
final class HingeObservingView: UIView {
    weak var monitor: DevicePostureMonitor?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        installHingeInteraction()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // Outside a window no further updates arrive, so drop a stale posture
        // rather than leaving the last one pinned.
        if window == nil {
            monitor?.update(.unavailable)
        }
    }

    private func installHingeInteraction() {
        #if compiler(>=6.4)
        // `compiler` gates the API's existence because SDKs before Xcode 27.1 do
        // not declare UIHinge at all, and `@available` alone only guards the
        // runtime, not whether the type compiles.
        guard #available(iOS 27.1, *) else {
            return
        }

        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else {
                return
            }

            guard let hinge = update.hinge else {
                monitor?.update(.unavailable)
                return
            }

            monitor?.update(DevicePosture(hinge.status, angle: hinge.angle))
        }

        addInteraction(interaction)
        #endif
    }
}

#if compiler(>=6.4)
@available(iOS 27.1, *)
extension DevicePosture {
    init(_ status: UIHinge.Status, angle: CGFloat) {
        switch status {
        case .closed:
            self = .closed
        case .partiallyOpen:
            self = .partiallyOpen(angle: Double(angle))
        case .fullyOpen:
            self = .fullyOpen
        case .unknown:
            self = .unavailable
        @unknown default:
            self = .unavailable
        }
    }
}
#endif

#endif
