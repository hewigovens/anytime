import Foundation

public enum ClockHourFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case twentyFourHour
    case twelveHour

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .twentyFourHour:
            "24-hour"
        case .twelveHour:
            "12-hour (AM/PM)"
        }
    }

    public var usesMeridiem: Bool {
        self == .twelveHour
    }

    public func pickerLocale(base: Locale = .autoupdatingCurrent) -> Locale {
        let separator = base.identifier.contains("@") ? ";" : "@"
        let hourCycle = switch self {
        case .twentyFourHour:
            "h23"
        case .twelveHour:
            "h12"
        }

        return Locale(identifier: "\(base.identifier)\(separator)hours=\(hourCycle)")
    }

    public static func defaultForCurrentLocale(_ locale: Locale = .autoupdatingCurrent) -> ClockHourFormat {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""

        if format.contains("a") || format.contains("h") || format.contains("K") {
            return .twelveHour
        }

        return .twentyFourHour
    }
}
