import AnyTimeCore
import SwiftUI

@MainActor
@Observable
final class DevicePostureMonitor {
    private(set) var posture: DevicePosture

    init() {
        posture = DevicePostureOverride.current ?? .unavailable
    }

    func update(_ posture: DevicePosture) {
        guard DevicePostureOverride.current == nil, posture != self.posture else {
            return
        }

        self.posture = posture
    }
}

#if canImport(UIKit)
import UIKit

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

        if window == nil {
            monitor?.update(.unavailable)
        }
    }

    private func installHingeInteraction() {
        #if compiler(>=6.4)
        // Older SDKs lack these types, so a runtime availability check is insufficient.
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
