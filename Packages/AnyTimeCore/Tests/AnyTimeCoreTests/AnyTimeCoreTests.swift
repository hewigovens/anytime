import XCTest
@testable import AnyTimeCore

@MainActor
final class AnyTimeCoreTests: XCTestCase {
    func testDefaultConfigurationKeepsCurrentZoneFirst() {
        let configuration = WorldClockConfiguration.default(currentTimeZoneID: "Asia/Tokyo")

        XCTAssertEqual(configuration.favoriteTimeZoneIDs.first, "Asia/Tokyo")
        XCTAssertTrue(configuration.favoriteTimeZoneIDs.contains("UTC"))
        XCTAssertEqual(Set(configuration.favoriteTimeZoneIDs).count, configuration.favoriteTimeZoneIDs.count)
    }

    func testSettingReferenceMovesZoneToFront() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["UTC", "Asia/Tokyo", "America/New_York"]
                )
            ),
            now: fixedDate
        )

        store.setReferenceTimeZone(id: "America/New_York")

        XCTAssertEqual(store.favoriteTimeZoneIDs, ["America/New_York", "UTC", "Asia/Tokyo"])
        XCTAssertEqual(store.presentations.first?.comparisonText, "Reference zone")
    }

    func testRemovingLastClockIsIgnored() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(favoriteTimeZoneIDs: ["UTC"])
            ),
            now: fixedDate
        )

        store.removeTimeZone(id: "UTC")

        XCTAssertEqual(store.favoriteTimeZoneIDs, ["UTC"])
    }

    func testPresentationContainsRelativeOffsetAndDay() throws {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["America/Los_Angeles", "Asia/Tokyo"]
                )
            ),
            now: crossingDate
        )

        let tokyo = try XCTUnwrap(store.presentations.last)

        XCTAssertEqual(tokyo.utcOffsetText, "UTC+9")
        XCTAssertEqual(tokyo.comparisonText, "17h ahead")
        XCTAssertEqual(tokyo.dayText, "Tomorrow")
    }

    func testDisplayedPresentationsHideZonesMatchingReferenceTime() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["UTC", "Europe/London", "Asia/Tokyo"]
                )
            ),
            now: fixedDate
        )

        XCTAssertEqual(store.presentations.map(\.timeZoneID), ["UTC", "Europe/London", "Asia/Tokyo"])
        XCTAssertEqual(store.displayedPresentations.map(\.timeZoneID), ["UTC", "Asia/Tokyo"])
    }

    func testPresentationsRefreshWhenReferenceDateChanges() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(favoriteTimeZoneIDs: ["UTC"])
            ),
            now: fixedDate
        )

        let initialTime = store.referencePresentation?.formattedTime

        store.referenceDate = fixedDate.addingTimeInterval(3_600)

        XCTAssertNotEqual(store.referencePresentation?.formattedTime, initialTime)
    }

    func testTimeOnlyFormatRespectsTwentyFourHourFormat() {
        let formatted = ClockDateStyle.timeOnly.formatted(
            date: formattedDate,
            in: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US_POSIX"),
            hourFormat: .twentyFourHour
        )

        XCTAssertEqual(formatted, "14:05")
    }

    func testTimeOnlyFormatRespectsTwelveHourFormat() {
        let formatted = ClockDateStyle.timeOnly.formatted(
            date: formattedDate,
            in: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US_POSIX"),
            hourFormat: .twelveHour
        )

        let normalized = formatted.replacingOccurrences(of: "\u{202F}", with: " ")

        XCTAssertEqual(normalized, "2:05 PM")
    }

    func testSearchIncludesAlreadySelectedZones() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["UTC", "Asia/Tokyo"]
                )
            ),
            now: fixedDate
        )

        let results = store.searchSections(matching: "tokyo")
        let identifiers = results.flatMap(\.items).map(\.identifier)

        XCTAssertTrue(identifiers.contains("Asia/Tokyo"))
    }

    func testSearchPrioritizesAbbreviationMatches() {
        let catalog = TimeZoneCatalog(identifiers: ["America/Los_Angeles", "America/Phoenix", "UTC"])

        let topResult = catalog.sections(matching: "pst").first?.items.first?.identifier

        XCTAssertEqual(topResult, "America/Los_Angeles")
    }

    func testSearchMatchesUTCOffsetQueries() {
        let catalog = TimeZoneCatalog(identifiers: ["America/Los_Angeles", "Asia/Tokyo", "UTC"])

        let topResult = catalog.sections(matching: "utc+9").first?.items.first?.identifier

        XCTAssertEqual(topResult, "Asia/Tokyo")
    }

    func testSearchRanksMultiWordPrefixMatchesAheadOfSimpleContains() {
        let catalog = TimeZoneCatalog(identifiers: ["America/Los_Angeles", "Australia/Melbourne", "Asia/Tokyo"])

        let topResult = catalog.sections(matching: "los ang").first?.items.first?.identifier

        XCTAssertEqual(topResult, "America/Los_Angeles")
    }

    func testSearchPrioritizesExactCityMatches() {
        let catalog = TimeZoneCatalog(identifiers: ["Asia/Tokyo", "America/Toronto", "America/Detroit"])

        let topResult = catalog.sections(matching: "tokyo").first?.items.first?.identifier

        XCTAssertEqual(topResult, "Asia/Tokyo")
    }

    func testSearchMatchesCanonicalCityAliases() {
        let catalog = TimeZoneCatalog(identifiers: ["Asia/Shanghai", "Asia/Tokyo", "UTC"])

        let topResult = catalog.sections(matching: "beijing").first?.items.first?.identifier

        XCTAssertEqual(topResult, "Asia/Shanghai")
    }

    func testSearchMatchesLegacySpellings() {
        let catalog = TimeZoneCatalog(identifiers: ["Europe/Kyiv", "Europe/London"])

        let topResult = catalog.sections(matching: "kiev").first?.items.first?.identifier

        XCTAssertEqual(topResult, "Europe/Kyiv")
    }

    func testFreeformSearchFindsCityInsideLongerSentence() {
        let catalog = TimeZoneCatalog(identifiers: ["Asia/Shanghai", "Asia/Tokyo", "UTC"])

        let match = catalog.bestMatch(inFreeformText: "Let's meet in Beijing tomorrow at 7 pm.")

        XCTAssertEqual(match?.timeZoneID, "Asia/Shanghai")
        XCTAssertEqual(match?.matchedQuery, "beijing")
    }

    func testFreeformSearchFindsAbbreviationInsideLongerSentence() {
        let catalog = TimeZoneCatalog(identifiers: ["America/Los_Angeles", "Asia/Tokyo", "UTC"])

        let match = catalog.bestMatch(inFreeformText: "Sync at 10am PST tomorrow.")

        XCTAssertEqual(match?.timeZoneID, "America/Los_Angeles")
        XCTAssertEqual(match?.matchedQuery, "pst")
    }

    func testSelectingSuggestedCityPreservesPreferredDisplayName() throws {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["UTC", "Asia/Tokyo"]
                )
            ),
            now: fixedDate
        )

        store.selectTimeZone(id: "Asia/Shanghai", preferredCityName: "Beijing")

        XCTAssertEqual(store.favoriteTimeZoneIDs, ["UTC", "Asia/Shanghai", "Asia/Tokyo"])

        let beijing = try XCTUnwrap(store.presentations.dropFirst().first)

        XCTAssertEqual(beijing.timeZoneID, "Asia/Shanghai")
        XCTAssertEqual(beijing.title, "Beijing")
        XCTAssertEqual(beijing.selectionTitle, "Beijing (Asia/Shanghai)")
    }

    func testSettingPreferredCityZoneAsReferenceKeepsPreferredName() {
        let store = WorldClockStore(
            persistence: InMemoryPersistence(
                configuration: WorldClockConfiguration(
                    favoriteTimeZoneIDs: ["UTC", "Asia/Tokyo"]
                )
            ),
            now: fixedDate
        )

        store.selectTimeZone(id: "Asia/Shanghai", preferredCityName: "Beijing")
        store.setReferenceTimeZone(id: "Asia/Shanghai")

        XCTAssertEqual(store.referenceCityName, "Beijing")
        XCTAssertEqual(store.referencePresentation?.title, "Beijing")
    }

    func testClockHourFormatDefaultsFollowLocaleConventions() {
        XCTAssertEqual(ClockHourFormat.defaultForCurrentLocale(Locale(identifier: "en_US")), .twelveHour)
        XCTAssertEqual(ClockHourFormat.defaultForCurrentLocale(Locale(identifier: "en_GB")), .twentyFourHour)
    }

}

private let fixedDate = ISO8601DateFormatter().date(from: "2024-01-15T12:00:00Z")!
private let crossingDate = ISO8601DateFormatter().date(from: "2024-01-15T23:00:00Z")!
private let formattedDate = ISO8601DateFormatter().date(from: "2024-01-15T14:05:00Z")!

private struct InMemoryPersistence: WorldClockPersisting {
    let configuration: WorldClockConfiguration?

    func loadConfiguration() -> WorldClockConfiguration? {
        configuration
    }

    func saveConfiguration(_ configuration: WorldClockConfiguration) {}
}
