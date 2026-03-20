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
        let unquotedFormat = format.removingQuotedDateFormatLiterals()

        if unquotedFormat.contains("a") || unquotedFormat.contains("h") || unquotedFormat.contains("K") {
            return .twelveHour
        }

        return .twentyFourHour
    }
}

private extension String {
    func removingQuotedDateFormatLiterals() -> String {
        var result = ""
        var index = startIndex
        var isInsideQuote = false

        while index < endIndex {
            let character = self[index]
            let nextIndex = self.index(after: index)

            if character == "'" {
                if nextIndex < endIndex, self[nextIndex] == "'" {
                    if isInsideQuote == false {
                        result.append("'")
                    }
                    index = self.index(after: nextIndex)
                    continue
                }

                isInsideQuote.toggle()
            } else if isInsideQuote == false {
                result.append(character)
            }

            index = nextIndex
        }

        return result
    }
}
