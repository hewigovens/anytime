import Foundation

public struct TimeZoneSection: Identifiable, Hashable, Sendable {
    public let title: String
    public let items: [TimeZoneDescriptor]

    public var id: String { title }

    public init(title: String, items: [TimeZoneDescriptor]) {
        self.title = title
        self.items = items
    }
}

public struct ClockPresentation: Identifiable, Equatable, Sendable {
    public let timeZoneID: String
    public let selectionTitle: String
    public let title: String
    public let subtitle: String
    public let formattedTime: String
    public let utcOffsetText: String
    public let comparisonText: String
    public let dayText: String?
    public let copyText: String
    public let isReference: Bool
    public let isSameTimeAsReference: Bool

    public var id: String { timeZoneID }
}
