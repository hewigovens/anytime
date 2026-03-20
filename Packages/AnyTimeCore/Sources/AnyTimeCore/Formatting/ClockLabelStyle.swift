public enum ClockLabelStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case city
    case abbreviation

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .city:
            "City"
        case .abbreviation:
            "Abbreviation"
        }
    }
}
