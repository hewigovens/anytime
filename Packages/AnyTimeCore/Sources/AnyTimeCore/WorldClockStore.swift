import Foundation
import Observation

@MainActor
@Observable
public final class WorldClockStore {
    public var referenceDate: Date {
        didSet {
            refreshPresentations()
        }
    }

    public private(set) var presentations: [ClockPresentation] = []

    public var labelStyle: ClockLabelStyle {
        get { configuration.labelStyle }
        set {
            mutateConfiguration { configuration in
                configuration.labelStyle = newValue
            }
        }
    }

    public var dateStyle: ClockDateStyle {
        get { configuration.dateStyle }
        set {
            mutateConfiguration { configuration in
                configuration.dateStyle = newValue
            }
        }
    }

    public var usesLocationTimeZone: Bool {
        get { configuration.usesLocationTimeZone }
        set {
            mutateConfiguration { configuration in
                configuration.usesLocationTimeZone = newValue
                guard newValue else {
                    return
                }

                let automaticTimeZoneID = configuration.automaticTimeZoneID ?? currentTimeZoneID
                configuration.automaticTimeZoneID = automaticTimeZoneID
                configuration.favoriteTimeZoneIDs.removeAll { $0 == automaticTimeZoneID }
                configuration.favoriteTimeZoneIDs.insert(automaticTimeZoneID, at: 0)
            }
        }
    }

    public var favoriteTimeZoneIDs: [String] {
        configuration.favoriteTimeZoneIDs
    }

    public var hasMultipleFavorites: Bool {
        configuration.favoriteTimeZoneIDs.count > 1
    }

    public var referenceTimeZoneID: String {
        configuration.favoriteTimeZoneIDs.first ?? currentTimeZoneID
    }

    public var referenceTimeZone: TimeZone {
        TimeZone(identifier: referenceTimeZoneID) ?? .autoupdatingCurrent
    }

    public var referenceDescriptor: TimeZoneDescriptor {
        descriptor(for: referenceTimeZoneID) ?? TimeZoneDescriptor(identifier: currentTimeZoneID)!
    }

    public var referenceCityName: String {
        preferredCityName(for: referenceTimeZoneID, descriptor: referenceDescriptor)
    }

    public var referencePresentation: ClockPresentation? {
        presentations.first
    }

    public var displayedPresentations: [ClockPresentation] {
        presentations.filter { presentation in
            presentation.isReference || presentation.isSameTimeAsReference == false
        }
    }

    private let persistence: any WorldClockPersisting
    private let currentTimeZoneID: String
    private var configuration: WorldClockConfiguration

    public init(
        persistence: any WorldClockPersisting = UserDefaultsWorldClockPersistence(),
        now: Date = .now,
        currentTimeZoneID: String = TimeZone.autoupdatingCurrent.identifier
    ) {
        self.persistence = persistence
        self.currentTimeZoneID = currentTimeZoneID
        referenceDate = now

        let stored = persistence.loadConfiguration() ?? .default(currentTimeZoneID: currentTimeZoneID)
        configuration = Self.sanitized(stored, currentTimeZoneID: currentTimeZoneID)
        refreshPresentations()
        persistence.saveConfiguration(configuration)
    }

    public func searchSections(matching query: String) -> [TimeZoneSection] {
        TimeZoneCatalog.shared.sections(matching: query)
    }

    public func selectTimeZone(id: String, preferredCityName: String? = nil) {
        let normalizedPreferredCityName = normalizedPreferredCityName(preferredCityName, for: id)

        mutateConfiguration { configuration in
            if let normalizedPreferredCityName {
                configuration.preferredCityNamesByTimeZoneID[id] = normalizedPreferredCityName
            }

            if let index = configuration.favoriteTimeZoneIDs.firstIndex(of: id) {
                let timeZoneID = configuration.favoriteTimeZoneIDs.remove(at: index)
                configuration.favoriteTimeZoneIDs.insert(timeZoneID, at: 0)
            } else {
                let insertionIndex = min(1, configuration.favoriteTimeZoneIDs.count)
                configuration.favoriteTimeZoneIDs.insert(id, at: insertionIndex)
            }
        }
    }

    public func setReferenceTimeZone(id: String) {
        mutateConfiguration { configuration in
            guard let index = configuration.favoriteTimeZoneIDs.firstIndex(of: id) else {
                return
            }

            let timeZoneID = configuration.favoriteTimeZoneIDs.remove(at: index)
            configuration.favoriteTimeZoneIDs.insert(timeZoneID, at: 0)
        }
    }

    public func addTimeZone(id: String) {
        mutateConfiguration { configuration in
            guard configuration.favoriteTimeZoneIDs.contains(id) == false else {
                return
            }
            configuration.favoriteTimeZoneIDs.append(id)
        }
    }

    public func removeTimeZone(id: String) {
        mutateConfiguration { configuration in
            guard configuration.favoriteTimeZoneIDs.count > 1 else {
                return
            }
            configuration.favoriteTimeZoneIDs.removeAll { $0 == id }
            configuration.preferredCityNamesByTimeZoneID[id] = nil
        }
    }

    public func moveTimeZones(fromOffsets: IndexSet, toOffset: Int) {
        mutateConfiguration { configuration in
            configuration.favoriteTimeZoneIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }

    public func moveDisplayedTimeZones(fromOffsets: IndexSet, toOffset: Int) {
        let displayedIDs = displayedPresentations.map(\.timeZoneID)
        var reorderedDisplayedIDs = displayedIDs
        reorderedDisplayedIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)

        mutateConfiguration { configuration in
            let displayedIDSet = Set(displayedIDs)
            let hiddenIDs = configuration.favoriteTimeZoneIDs.filter { identifier in
                displayedIDSet.contains(identifier) == false
            }
            let hiddenIDSet = Set(hiddenIDs)
            var remainingDisplayedIDs = reorderedDisplayedIDs[...]

            configuration.favoriteTimeZoneIDs = configuration.favoriteTimeZoneIDs.map { identifier in
                if hiddenIDSet.contains(identifier) {
                    return identifier
                }

                return remainingDisplayedIDs.removeFirst()
            }
        }
    }

    public func shiftReference(hours: Int) {
        guard hours != 0 else {
            return
        }
        referenceDate = referenceDate.addingTimeInterval(TimeInterval(hours) * 3_600)
    }

    public func shiftReference(days: Int) {
        guard days != 0 else {
            return
        }
        referenceDate = referenceDate.addingTimeInterval(TimeInterval(days) * 86_400)
    }

    public func resetReferenceDate() {
        referenceDate = .now
    }

    public func restoreDefaults() {
        configuration = .default(currentTimeZoneID: currentTimeZoneID)
        refreshPresentations()
        persistence.saveConfiguration(configuration)
    }

    public func updateAutomaticTimeZone(id: String) {
        guard TimeZone(identifier: id) != nil else {
            return
        }

        mutateConfiguration { configuration in
            let previousAutomaticTimeZoneID = configuration.automaticTimeZoneID
            configuration.automaticTimeZoneID = id

            guard configuration.usesLocationTimeZone else {
                return
            }

            configuration.favoriteTimeZoneIDs.removeAll { favoriteID in
                favoriteID == id || favoriteID == previousAutomaticTimeZoneID
            }
            configuration.favoriteTimeZoneIDs.insert(id, at: 0)
        }
    }

    private func refreshPresentations() {
        let referenceTimeZoneID = referenceTimeZoneID
        let referenceTimeZone = referenceTimeZone
        let referenceOffsetSeconds = referenceTimeZone.secondsFromGMT(for: referenceDate)

        presentations = configuration.favoriteTimeZoneIDs.compactMap { identifier in
            makePresentation(
                for: identifier,
                referenceTimeZoneID: referenceTimeZoneID,
                referenceTimeZone: referenceTimeZone,
                referenceOffsetSeconds: referenceOffsetSeconds
            )
        }
    }

    private func makePresentation(
        for identifier: String,
        referenceTimeZoneID: String,
        referenceTimeZone: TimeZone,
        referenceOffsetSeconds: Int
    ) -> ClockPresentation? {
        guard
            let descriptor = descriptor(for: identifier),
            let timeZone = TimeZone(identifier: identifier)
        else {
            return nil
        }

        let abbreviation = descriptor.abbreviation(at: referenceDate)
        let cityName = preferredCityName(for: identifier, descriptor: descriptor)
        let targetOffsetSeconds = timeZone.secondsFromGMT(for: referenceDate)
        let isSameTimeAsReference = identifier != referenceTimeZoneID && targetOffsetSeconds == referenceOffsetSeconds
        let utcOffsetText = ClockMath.utcOffsetText(seconds: targetOffsetSeconds)
        let comparisonText = identifier == referenceTimeZoneID
            ? "Reference zone"
            : ClockMath.comparisonText(
                targetSeconds: targetOffsetSeconds,
                referenceSeconds: referenceOffsetSeconds
            )

        let title: String
        let subtitle: String
        switch configuration.labelStyle {
        case .city:
            title = cityName
            subtitle = "\(abbreviation) • \(descriptor.locationLine)"
        case .abbreviation:
            title = abbreviation
            subtitle = "\(cityName) • \(descriptor.locationLine)"
        }

        let dayText = identifier == referenceTimeZoneID
            ? nil
            : ClockMath.dayText(
                for: referenceDate,
                targetTimeZone: timeZone,
                referenceTimeZone: referenceTimeZone
            )

        let formattedTime = configuration.dateStyle.formatted(
            date: referenceDate,
            in: timeZone
        )

        let copyText = "\(cityName): \(formattedTime) (\(utcOffsetText))"
        let selectionTitle = cityName == descriptor.city
            ? descriptor.selectionTitle
            : "\(cityName) (\(identifier))"

        return ClockPresentation(
            timeZoneID: identifier,
            selectionTitle: selectionTitle,
            title: title,
            subtitle: subtitle,
            formattedTime: formattedTime,
            utcOffsetText: utcOffsetText,
            comparisonText: comparisonText,
            dayText: dayText,
            copyText: copyText,
            isReference: identifier == referenceTimeZoneID,
            isSameTimeAsReference: isSameTimeAsReference
        )
    }

    private func mutateConfiguration(_ mutate: (inout WorldClockConfiguration) -> Void) {
        var next = configuration
        mutate(&next)
        let sanitized = Self.sanitized(next, currentTimeZoneID: currentTimeZoneID)
        guard sanitized != configuration else {
            return
        }

        configuration = sanitized
        refreshPresentations()
        persistence.saveConfiguration(configuration)
    }

    private func descriptor(for identifier: String) -> TimeZoneDescriptor? {
        TimeZoneDescriptor(identifier: identifier)
    }

    private func preferredCityName(for identifier: String, descriptor: TimeZoneDescriptor) -> String {
        configuration.preferredCityNamesByTimeZoneID[identifier] ?? descriptor.city
    }

    private func normalizedPreferredCityName(_ name: String?, for identifier: String) -> String? {
        guard
            let descriptor = descriptor(for: identifier),
            let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines),
            trimmedName.isEmpty == false
        else {
            return nil
        }

        if trimmedName.compare(descriptor.city, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            return nil
        }

        return trimmedName
    }

    private static func sanitized(
        _ configuration: WorldClockConfiguration,
        currentTimeZoneID: String
    ) -> WorldClockConfiguration {
        var sanitized = configuration
        sanitized.favoriteTimeZoneIDs = ClockMath.uniqueValidTimeZoneIDs(from: configuration.favoriteTimeZoneIDs)
        let validFavoriteIDs = Set(sanitized.favoriteTimeZoneIDs)
        sanitized.preferredCityNamesByTimeZoneID = configuration.preferredCityNamesByTimeZoneID.reduce(into: [:]) { result, entry in
            guard validFavoriteIDs.contains(entry.key) else {
                return
            }

            let trimmedName = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedName.isEmpty == false else {
                return
            }

            if let descriptor = TimeZoneDescriptor(identifier: entry.key),
               trimmedName.compare(descriptor.city, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                return
            }

            result[entry.key] = trimmedName
        }
        if let automaticTimeZoneID = configuration.automaticTimeZoneID,
           TimeZone(identifier: automaticTimeZoneID) != nil {
            sanitized.automaticTimeZoneID = automaticTimeZoneID
        } else {
            sanitized.automaticTimeZoneID = currentTimeZoneID
        }

        if sanitized.usesLocationTimeZone, let automaticTimeZoneID = sanitized.automaticTimeZoneID {
            sanitized.favoriteTimeZoneIDs.removeAll { $0 == automaticTimeZoneID }
            sanitized.favoriteTimeZoneIDs.insert(automaticTimeZoneID, at: 0)
        }

        if sanitized.favoriteTimeZoneIDs.isEmpty {
            sanitized = .default(currentTimeZoneID: currentTimeZoneID)
        }

        return sanitized
    }
}

private extension Array where Element == String {
    mutating func move(fromOffsets offsets: IndexSet, toOffset: Int) {
        let moving = offsets.map { self[$0] }
        remove(atOffsets: offsets)
        insert(contentsOf: moving, at: Swift.min(toOffset, count))
    }

    mutating func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            remove(at: offset)
        }
    }
}
