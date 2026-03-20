import Foundation

public struct TimeZoneCatalog: Sendable {
    public static let shared = TimeZoneCatalog()

    private let entries: [SearchEntry]

    public init(identifiers: [String]? = nil) {
        let sourceIdentifiers = identifiers ?? Self.defaultIdentifiers
        entries = sourceIdentifiers
            .compactMap(TimeZoneDescriptor.init(identifier:))
            .sorted { lhs, rhs in
                if lhs.sectionTitle != rhs.sectionTitle {
                    return lhs.sectionTitle < rhs.sectionTitle
                }
                if lhs.city != rhs.city {
                    return lhs.city < rhs.city
                }
                return lhs.identifier < rhs.identifier
            }
            .map(SearchEntry.init)
    }

    public func sections(
        matching query: String,
        excluding excludedIdentifiers: Set<String> = []
    ) -> [TimeZoneSection] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).normalizedSearchText
        let queryWords = normalizedQuery.searchWords

        let matches = entries.compactMap { entry -> ScoredDescriptor? in
            guard excludedIdentifiers.contains(entry.descriptor.identifier) == false else {
                return nil
            }
            guard normalizedQuery.isEmpty == false else {
                return ScoredDescriptor(descriptor: entry.descriptor, score: 0)
            }

            let score = score(
                entry: entry,
                normalizedQuery: normalizedQuery,
                queryWords: queryWords
            )

            guard score > 0 else {
                return nil
            }
            return ScoredDescriptor(descriptor: entry.descriptor, score: score)
        }

        let grouped = Dictionary(grouping: matches, by: \.descriptor.sectionTitle)

        let sectionKeys: [String]
        if normalizedQuery.isEmpty {
            sectionKeys = grouped.keys.sorted()
        } else {
            sectionKeys = grouped.keys.sorted { lhs, rhs in
                let lhsTopScore = grouped[lhs, default: []].map(\.score).max() ?? 0
                let rhsTopScore = grouped[rhs, default: []].map(\.score).max() ?? 0
                if lhsTopScore != rhsTopScore {
                    return lhsTopScore > rhsTopScore
                }
                return lhs < rhs
            }
        }

        return sectionKeys.map { key in
            let items = grouped[key, default: []].sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                if lhs.descriptor.city != rhs.descriptor.city {
                    return lhs.descriptor.city < rhs.descriptor.city
                }
                return lhs.descriptor.identifier < rhs.descriptor.identifier
            }
            .map(\.descriptor)

            return TimeZoneSection(title: key, items: items)
        }
    }

    public func bestMatch(inFreeformText text: String) -> TimeZoneFreeformMatch? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).normalizedSearchText
        guard normalizedText.isEmpty == false else {
            return nil
        }

        var bestMatch: TimeZoneFreeformMatch?
        var bestScore = 0

        for candidate in Self.freeformCandidates(from: normalizedText) {
            let queryWords = candidate.searchWords

            for entry in entries {
                let candidateScore = score(
                    entry: entry,
                    normalizedQuery: candidate,
                    queryWords: queryWords
                )

                guard candidateScore > 0 else {
                    continue
                }

                let phraseBonus = max(0, queryWords.count - 1) * 140
                let totalScore = candidateScore + phraseBonus

                guard totalScore > bestScore else {
                    continue
                }

                bestScore = totalScore
                bestMatch = TimeZoneFreeformMatch(
                    descriptor: entry.descriptor,
                    matchedQuery: candidate
                )
            }
        }

        return bestMatch
    }

    private static let defaultIdentifiers: [String] = {
        let filtered = TimeZone.knownTimeZoneIdentifiers.filter { identifier in
            identifier.hasPrefix("SystemV") == false &&
                identifier.hasPrefix("US/") == false &&
                identifier.hasPrefix("Canada/") == false
        }
        return ["UTC"] + filtered
    }()

    private static func freeformCandidates(from normalizedText: String) -> [String] {
        let words = normalizedText.searchWords
        guard words.isEmpty == false else {
            return [normalizedText]
        }

        var ordered: [String] = []
        var seen = Set<String>()

        func append(_ candidate: String) {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard
                trimmed.isEmpty == false,
                seen.insert(trimmed).inserted
            else {
                return
            }
            ordered.append(trimmed)
        }

        append(normalizedText)

        let maxPhraseLength = min(4, words.count)
        if maxPhraseLength >= 2 {
            for phraseLength in stride(from: maxPhraseLength, through: 2, by: -1) {
                for startIndex in 0...(words.count - phraseLength) {
                    let phrase = words[startIndex ..< (startIndex + phraseLength)].joined(separator: " ")
                    append(phrase)
                }
            }
        }

        for word in words where Self.isMeaningfulFreeformWord(word) {
            append(word)
        }

        return ordered
    }

    private static func isMeaningfulFreeformWord(_ word: String) -> Bool {
        guard word.isEmpty == false else {
            return false
        }

        if word.count >= 3 {
            return true
        }

        return word.contains("+") || word.contains("-") || word.contains(":") || word.contains("/")
    }
}

private extension TimeZoneCatalog {
    func score(
        entry: SearchEntry,
        normalizedQuery: String,
        queryWords: [String]
    ) -> Int {
        let terms = entry.normalizedTerms
        let words = entry.normalizedWords
        var score = 0

        if entry.normalizedCity == normalizedQuery {
            score += 4_000
        }

        if entry.normalizedIdentifier == normalizedQuery {
            score += 3_400
        }

        if terms.contains(normalizedQuery) {
            score += 2_800
        }

        if entry.normalizedCity.hasPrefix(normalizedQuery) {
            score += 2_100
        }

        if entry.normalizedIdentifier.hasPrefix(normalizedQuery) {
            score += 1_700
        }

        if terms.contains(where: { $0.hasPrefix(normalizedQuery) }) {
            score += 1_400
        }

        if words.contains(where: { $0.hasPrefix(normalizedQuery) }) {
            score += 1_000
        }

        if entry.searchIndex.contains(normalizedQuery) {
            score += 380
        }

        if queryWords.isEmpty == false {
            let matchedWordCount = queryWords.filter { queryWord in
                words.contains(where: { $0.hasPrefix(queryWord) || $0.contains(queryWord) })
            }.count

            if matchedWordCount == queryWords.count {
                score += 900 + (matchedWordCount * 120)
            } else {
                score += matchedWordCount * 120
            }
        }

        return score
    }
}

private struct SearchEntry: Sendable {
    let descriptor: TimeZoneDescriptor
    let normalizedCity: String
    let normalizedIdentifier: String
    let normalizedTerms: [String]
    let normalizedWords: [String]
    let searchIndex: String

    init(descriptor: TimeZoneDescriptor) {
        self.descriptor = descriptor
        normalizedCity = descriptor.city.normalizedSearchText
        normalizedIdentifier = descriptor.identifier.normalizedSearchText

        let normalizedTerms = Array(Set(descriptor.searchTerms.map(\.normalizedSearchText)))
        self.normalizedTerms = normalizedTerms
        normalizedWords = Array(Set(normalizedTerms.flatMap(\.searchWords)))
        searchIndex = normalizedTerms.joined(separator: " ")
    }
}

private struct ScoredDescriptor {
    let descriptor: TimeZoneDescriptor
    let score: Int
}
