import AnyTimeCore
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Publishes the device's hinge posture so the home screen can pick a layout.
///
/// `UIHingeInteraction` only reports through an interaction attached to a view,
/// so this model is driven by ``HingePostureReader``.
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

/// Reports hinge changes from the view hierarchy to a ``DevicePostureMonitor``.
///
/// The hinge API ships in the iOS 27.1 SDK, which is Xcode 27.1 or later. Older
/// SDKs cannot see `UIHinge` at all — `@available` only guards the runtime, not
/// the type's existence — so the reader degrades to a plain view there and the
/// layout falls back to the size-driven policy.
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

/// A view that owns a hinge interaction for its lifetime.
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
        // instead of leaving the last one pinned.
        if window == nil {
            monitor?.update(.unavailable)
        }
    }

    private func installHingeInteraction() {
        #if compiler(>=6.4)
        // Xcode 27.1 and later: the SDK provides the hinge API. The runtime
        // check still matters, because the app also runs on iOS 17 and later.
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
