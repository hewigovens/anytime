import Foundation

public enum ClockDateStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case timeOnly
    case weekdayAndTime
    case dateAndTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .timeOnly:
            "Time only"
        case .weekdayAndTime:
            "Weekday + time"
        case .dateAndTime:
            "Date + time"
        }
    }

    public func formatted(
        date: Date,
        in timeZone: TimeZone,
        locale: Locale = .autoupdatingCurrent,
        hourFormat: ClockHourFormat
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone

        switch self {
        case .timeOnly:
            formatter.setLocalizedDateFormatFromTemplate(hourFormat == .twentyFourHour ? "Hm" : "hma")
        case .weekdayAndTime:
            formatter.setLocalizedDateFormatFromTemplate(hourFormat == .twentyFourHour ? "EEEHm" : "EEEhma")
        case .dateAndTime:
            formatter.setLocalizedDateFormatFromTemplate(hourFormat == .twentyFourHour ? "yMMMdHm" : "yMMMdhma")
        }

        return formatter.string(from: date)
    }
}
