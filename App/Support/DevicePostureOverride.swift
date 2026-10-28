import AnyTimeCore
import Foundation

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
