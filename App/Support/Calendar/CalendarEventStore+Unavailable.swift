import AnyTimeCore
import Foundation

#if !canImport(EventKit)
@MainActor
final class CalendarEventStore {
    func createEvent(
        title: String,
        for presentation: ClockPresentation,
        referenceDate: Date
    ) async throws -> String {
        throw Error.unavailable
    }

    func defaultTitle(for presentation: ClockPresentation) -> String {
        "\(presentation.title) \(presentation.formattedTime)"
    }
}

private extension CalendarEventStore {
    enum Error: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "Calendar is unavailable on this device."
        }
    }
}
#endif
