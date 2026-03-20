public struct TimeZoneSection: Identifiable, Hashable, Sendable {
    public let title: String
    public let items: [TimeZoneDescriptor]

    public var id: String { title }

    public init(title: String, items: [TimeZoneDescriptor]) {
        self.title = title
        self.items = items
    }
}
