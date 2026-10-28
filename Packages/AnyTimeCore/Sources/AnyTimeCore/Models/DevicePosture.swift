public enum DevicePosture: Equatable, Sendable {
    case unavailable
    case closed
    case partiallyOpen(angle: Double)
    case fullyOpen

    public var isPartiallyOpen: Bool {
        if case .partiallyOpen = self {
            return true
        }

        return false
    }
}
