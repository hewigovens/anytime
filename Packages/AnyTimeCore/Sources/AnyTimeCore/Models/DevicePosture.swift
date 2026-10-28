/// The physical posture of a foldable device's hinge.
///
/// Non-foldable devices, and views that are not hosted in a hierarchy which
/// reports hinge updates, always report ``unavailable``.
public enum DevicePosture: Equatable, Sendable {
    /// No hinge information is available.
    case unavailable
    /// The hinge is fully closed, so only the outer display is usable.
    case closed
    /// The hinge is held somewhere between closed and fully open.
    ///
    /// The angle is in radians. It is carried for coarse decisions only: its
    /// update rate and precision are system policy, and it does not reveal which
    /// way the device is held, so layouts should branch on the posture instead.
    case partiallyOpen(angle: Double)
    /// The hinge is open as far as the device allows.
    case fullyOpen

    /// Whether the device is resting half open, for example on a table.
    public var isPartiallyOpen: Bool {
        if case .partiallyOpen = self {
            return true
        }

        return false
    }
}
