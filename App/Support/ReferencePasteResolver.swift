import AnyTimeCore
import Foundation

struct ReferencePasteResolution {
    let date: Date?
    let timeZoneID: String?
    let preferredCityName: String?
    let message: String
}

enum ReferencePasteResolutionResult {
    case success(ReferencePasteResolution)
    case failure(String)
}

@MainActor
enum ReferencePasteResolver {
    static func resolve(from clipboard: String) async -> ReferencePasteResolutionResult {
        let trimmedClipboard = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedClipboard.isEmpty == false else {
            return .failure("Clipboard is empty.")
        }

        let dateMatch = detectedDate(in: trimmedClipboard)
        var timeZoneID = explicitTimeZoneIdentifier(in: trimmedClipboard)
        var preferredCityName: String?
        let freeformMatch = TimeZoneCatalog.shared.bestMatch(inFreeformText: trimmedClipboard)

        if timeZoneID == nil, let offsetToken = explicitOffsetToken(in: trimmedClipboard) {
            timeZoneID = bestTimeZoneIdentifier(matching: offsetToken)
        }

        if timeZoneID == nil, let dateTimeZone = dateMatch?.timeZone {
            timeZoneID = bestTimeZoneIdentifier(matching: utcOffsetText(seconds: dateTimeZone.secondsFromGMT()))
        }

        if timeZoneID == nil, let freeformMatch {
            timeZoneID = freeformMatch.timeZoneID
            preferredCityName = preferredCityNameCandidate(
                from: freeformMatch.matchedQuery,
                fallbackTimeZoneID: freeformMatch.timeZoneID
            )
        }

        if let remoteQuery = remoteQuery(from: trimmedClipboard, freeformMatch: freeformMatch) {
            if let remoteMatch = try? await RemoteCityLookup.lookup(matching: remoteQuery).first {
                if timeZoneID == nil {
                    timeZoneID = remoteMatch.timeZoneID
                    preferredCityName = remoteMatch.title
                } else if timeZoneID == remoteMatch.timeZoneID {
                    preferredCityName = preferredCityName ?? remoteMatch.title
                }
            }
        }

        if timeZoneID == nil || preferredCityName == nil {
            if let hints = await foundationModelHints(for: trimmedClipboard) {
                if timeZoneID == nil, let hintedTimeZoneID = canonicalTimeZoneIdentifier(from: hints.timeZoneID) {
                    timeZoneID = hintedTimeZoneID
                }

                if timeZoneID == nil, let offsetToken = hints.offsetToken {
                    timeZoneID = bestTimeZoneIdentifier(matching: offsetToken)
                }

                if let hintedCityQuery = hints.cityQuery {
                    if let remoteMatch = try? await RemoteCityLookup.lookup(matching: hintedCityQuery).first {
                        if timeZoneID == nil {
                            timeZoneID = remoteMatch.timeZoneID
                            preferredCityName = remoteMatch.title
                        } else if timeZoneID == remoteMatch.timeZoneID {
                            preferredCityName = preferredCityName ?? remoteMatch.title
                        }
                    } else if timeZoneID == nil, let hintedMatch = TimeZoneCatalog.shared.bestMatch(inFreeformText: hintedCityQuery) {
                        timeZoneID = hintedMatch.timeZoneID
                        preferredCityName = preferredCityNameCandidate(
                            from: hintedCityQuery,
                            fallbackTimeZoneID: hintedMatch.timeZoneID
                        )
                    }
                }
            }
        }

        let resolvedDate = dateMatch?.date
        guard resolvedDate != nil || timeZoneID != nil else {
            return .failure("Couldn’t find a date or time zone in the clipboard.")
        }

        let zoneDisplayName = timeZoneDisplayName(
            timeZoneID: timeZoneID,
            preferredCityName: preferredCityName
        )

        return .success(
            ReferencePasteResolution(
                date: resolvedDate,
                timeZoneID: timeZoneID,
                preferredCityName: preferredCityName,
                message: feedbackMessage(
                    date: resolvedDate,
                    zoneDisplayName: zoneDisplayName
                )
            )
        )
    }

    private static func detectedDate(in text: String) -> DetectedDate? {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)
        guard let match = clipboardDateDetector.firstMatch(in: text, range: range) else {
            return nil
        }

        return DetectedDate(date: match.date, timeZone: match.timeZone)
    }

    private static func explicitTimeZoneIdentifier(in text: String) -> String? {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)

        for match in explicitTimeZoneRegex.matches(in: text, range: range) {
            guard
                let candidateRange = Range(match.range(at: 1), in: text)
            else {
                continue
            }

            let candidate = String(text[candidateRange])
            if let canonicalIdentifier = canonicalTimeZoneIdentifier(from: candidate) {
                return canonicalIdentifier
            }
        }

        return nil
    }

    private static func explicitOffsetToken(in text: String) -> String? {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)
        guard
            let match = explicitOffsetRegex.firstMatch(in: text, range: range),
            let candidateRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        let candidate = String(text[candidateRange])
            .replacingOccurrences(of: " ", with: "")
            .uppercased()

        return candidate
    }

    private static func bestTimeZoneIdentifier(matching query: String) -> String? {
        TimeZoneCatalog.shared.sections(matching: query).first?.items.first?.identifier
    }

    private static func remoteQuery(
        from text: String,
        freeformMatch: TimeZoneFreeformMatch?
    ) -> String? {
        if let freeformMatch {
            let candidate = freeformMatch.matchedQuery
            if looksLikeCityQuery(candidate) {
                return candidate
            }
        }

        if looksLikeCityQuery(text) {
            return text
        }

        return capitalizedLocationPhrase(in: text)
    }

    private static func capitalizedLocationPhrase(in text: String) -> String? {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)

        for match in capitalizedLocationRegex.matches(in: text, range: range) {
            guard let candidateRange = Range(match.range(at: 1), in: text) else {
                continue
            }

            let candidate = String(text[candidateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if looksLikeCityQuery(candidate) {
                return candidate
            }
        }

        return nil
    }

    private static func looksLikeCityQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return false
        }

        if trimmed.rangeOfCharacter(from: .decimalDigits) != nil {
            return false
        }

        let normalized = trimmed.normalizedPasteSearchText
        if normalized.contains("/") || normalized.contains("utc") || normalized.contains("gmt") {
            return false
        }

        let words = normalized.searchWords
        guard (1 ... 4).contains(words.count) else {
            return false
        }

        return words.allSatisfy { $0.count >= 2 }
    }

    private static func preferredCityNameCandidate(
        from query: String,
        fallbackTimeZoneID: String
    ) -> String? {
        guard
            looksLikeCityQuery(query),
            let descriptor = TimeZoneDescriptor(identifier: fallbackTimeZoneID)
        else {
            return nil
        }

        let normalizedQuery = query.normalizedPasteSearchText
        if normalizedQuery == descriptor.city.normalizedPasteSearchText {
            return nil
        }

        return query.titleCasedSearchQuery
    }

    private static func timeZoneDisplayName(
        timeZoneID: String?,
        preferredCityName: String?
    ) -> String? {
        guard let timeZoneID else {
            return nil
        }

        if let preferredCityName, preferredCityName.isEmpty == false {
            return preferredCityName
        }

        return TimeZoneDescriptor(identifier: timeZoneID)?.city ?? timeZoneID
    }

    private static func feedbackMessage(
        date: Date?,
        zoneDisplayName: String?
    ) -> String {
        switch (date, zoneDisplayName) {
        case let (date?, zone?):
            return "Updated to \(pasteFeedbackFormatter.string(from: date)) in \(zone)."
        case let (date?, nil):
            return "Updated time to \(pasteFeedbackFormatter.string(from: date))."
        case let (nil, zone?):
            return "Switched reference zone to \(zone)."
        default:
            return "Clipboard updated."
        }
    }

    private static func canonicalTimeZoneIdentifier(from candidate: String?) -> String? {
        guard let candidate else {
            return nil
        }

        let normalizedCandidate = candidate
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()

        guard normalizedCandidate.isEmpty == false else {
            return nil
        }

        return knownTimeZoneIdentifiersByNormalizedKey[normalizedCandidate]
    }

    private static func utcOffsetText(seconds: Int) -> String {
        let sign = seconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(seconds)
        let hours = absoluteSeconds / 3_600
        let minutes = (absoluteSeconds % 3_600) / 60

        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }

        return "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
    }

    private static func foundationModelHints(for text: String) async -> FoundationModelPasteHints? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await FoundationModelPasteInterpreter.interpret(text)
        }
        #endif

        return nil
    }

    private static let clipboardDateDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)

    private static let explicitTimeZoneRegex = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z0-9_])([A-Za-z]+(?:/[A-Za-z0-9_+\-]+)+)(?![A-Za-z0-9_])"#
    )

    private static let explicitOffsetRegex = try! NSRegularExpression(
        pattern: #"((?:UTC|GMT)\s*[+-]\s*\d{1,2}(?::?\d{2})?)"#,
        options: [.caseInsensitive]
    )

    private static let capitalizedLocationRegex = try! NSRegularExpression(
        pattern: #"([A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,3})"#
    )

    private static let knownTimeZoneIdentifiersByNormalizedKey = Dictionary(
        uniqueKeysWithValues: TimeZone.knownTimeZoneIdentifiers.map { identifier in
            (identifier.lowercased(), identifier)
        }
    )

    private static let pasteFeedbackFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct DetectedDate {
    let date: Date?
    let timeZone: TimeZone?
}

private extension String {
    var normalizedPasteSearchText: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)
            .lowercased()
    }

    var searchWords: [String] {
        components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: "+:-")))
            .filter { $0.isEmpty == false }
    }

    var titleCasedSearchQuery: String {
        localizedLowercase.capitalized
    }
}
