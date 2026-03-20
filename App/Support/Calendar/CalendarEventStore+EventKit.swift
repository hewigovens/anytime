import AnyTimeCore
import Foundation

#if canImport(EventKit)
import EventKit

@MainActor
final class CalendarEventStore {
    private let eventStore = EKEventStore()

    func createEvent(
        title: String,
        for presentation: ClockPresentation,
        referenceDate: Date
    ) async throws -> String {
        try await requestAccessIfNeeded()

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw Error.noCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        let savedTitle = sanitizedTitle(title, fallback: defaultTitle(for: presentation))
        event.calendar = calendar
        event.title = savedTitle
        event.notes = presentation.copyText
        event.startDate = referenceDate
        event.endDate = referenceDate.addingTimeInterval(60 * 60)
        event.timeZone = TimeZone(identifier: presentation.timeZoneID) ?? .autoupdatingCurrent

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
        } catch {
            throw Error.saveFailed
        }

        return "Added “\(savedTitle)” to Calendar for \(presentation.formattedTime)."
    }

    func defaultTitle(for presentation: ClockPresentation) -> String {
        "\(presentation.title) \(presentation.formattedTime)"
    }

    private func requestAccessIfNeeded() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly:
            return
        case .notDetermined:
            let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, any Swift.Error>) in
                eventStore.requestWriteOnlyAccessToEvents { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }

            guard granted else {
                throw Error.accessDenied
            }
        case .denied, .restricted:
            throw Error.accessDenied
        @unknown default:
            throw Error.accessDenied
        }
    }

    private func sanitizedTitle(_ title: String, fallback: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

private extension CalendarEventStore {
    enum Error: LocalizedError {
        case accessDenied
        case noCalendar
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                "Calendar access is unavailable. Allow Calendar access in Settings."
            case .noCalendar:
                "No calendar is available on this device."
            case .saveFailed:
                "Couldn’t save the calendar event."
            }
        }
    }
}
#endif
