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
}

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
