/// Non-foldable devices, and views outside a hierarchy that reports hinge
/// updates, always report ``unavailable``.
public enum DevicePosture: Equatable, Sendable {
    case unavailable
    case closed
    /// The angle is carried for coarse decisions only, and it does not reveal
    /// which way the device is held, so layouts should branch on the posture.
    case partiallyOpen(angle: Double)
    case fullyOpen

    public var isPartiallyOpen: Bool {
        if case .partiallyOpen = self {
            return true
        }

        return false
    }
}
