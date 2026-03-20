public struct TimeZoneFreeformMatch: Sendable {
    public let descriptor: TimeZoneDescriptor
    public let matchedQuery: String

    public var timeZoneID: String {
        descriptor.identifier
    }
}
