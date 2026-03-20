import Foundation

public struct WorldClockConfiguration: Codable, Equatable, Sendable {
    public var favoriteTimeZoneIDs: [String]
    public var preferredCityNamesByTimeZoneID: [String: String]
    public var labelStyle: ClockLabelStyle
    public var dateStyle: ClockDateStyle
    var explicitHourFormat: ClockHourFormat?

    public var hourFormat: ClockHourFormat {
        get { explicitHourFormat ?? .defaultForCurrentLocale() }
        set { explicitHourFormat = newValue }
    }

    public init(
        favoriteTimeZoneIDs: [String],
        preferredCityNamesByTimeZoneID: [String: String] = [:],
        labelStyle: ClockLabelStyle = .city,
        dateStyle: ClockDateStyle = .weekdayAndTime,
        hourFormat: ClockHourFormat? = nil
    ) {
        self.favoriteTimeZoneIDs = favoriteTimeZoneIDs
        self.preferredCityNamesByTimeZoneID = preferredCityNamesByTimeZoneID
        self.labelStyle = labelStyle
        self.dateStyle = dateStyle
        explicitHourFormat = hourFormat
    }

    enum CodingKeys: String, CodingKey {
        case favoriteTimeZoneIDs
        case preferredCityNamesByTimeZoneID
        case labelStyle
        case dateStyle
        case hourFormat
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favoriteTimeZoneIDs = try container.decode([String].self, forKey: .favoriteTimeZoneIDs)
        preferredCityNamesByTimeZoneID = try container.decodeIfPresent([String: String].self, forKey: .preferredCityNamesByTimeZoneID) ?? [:]
        labelStyle = try container.decodeIfPresent(ClockLabelStyle.self, forKey: .labelStyle) ?? .city
        dateStyle = try container.decodeIfPresent(ClockDateStyle.self, forKey: .dateStyle) ?? .weekdayAndTime
        explicitHourFormat = try container.decodeIfPresent(ClockHourFormat.self, forKey: .hourFormat)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(favoriteTimeZoneIDs, forKey: .favoriteTimeZoneIDs)
        try container.encode(preferredCityNamesByTimeZoneID, forKey: .preferredCityNamesByTimeZoneID)
        try container.encode(labelStyle, forKey: .labelStyle)
        try container.encode(dateStyle, forKey: .dateStyle)
        try container.encodeIfPresent(explicitHourFormat, forKey: .hourFormat)
    }

    public static func `default`(currentTimeZoneID: String) -> WorldClockConfiguration {
        let candidates = [
            currentTimeZoneID,
            "UTC",
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "America/Los_Angeles"
        ]

        return WorldClockConfiguration(
            favoriteTimeZoneIDs: ClockMath.uniqueValidTimeZoneIDs(from: candidates),
            preferredCityNamesByTimeZoneID: [:],
            labelStyle: .city,
            dateStyle: .weekdayAndTime
        )
    }
}
