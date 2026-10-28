import AnyTimeCore
import Foundation

/// Overrides the reported device posture so the foldable layouts can be
/// exercised in the Simulator, which cannot fold a device.
///
/// Set `ANYTIME_POSTURE_OVERRIDE` to `closed`, `partially-open`, or
/// `fully-open`. Anything else, including an unset value, leaves the posture to
/// the device.
enum DevicePostureOverride {
    private static let environment = ProcessInfo.processInfo.environment

    static var current: DevicePosture? {
        guard let rawValue = environment["ANYTIME_POSTURE_OVERRIDE"] else {
            return nil
        }

        switch rawValue {
        case "closed":
            return .closed
        case "partially-open":
            return .partiallyOpen(angle: .pi / 2)
        case "fully-open":
            return .fullyOpen
        default:
            return nil
        }
    }
}
