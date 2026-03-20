import AnyTimeCore
import CoreLocation
import Foundation

enum RemoteCityLookup {
    static func lookup(matching query: String) async throws -> [RemoteCityMatch] {
        let placemarks = try await CLGeocoder().geocodeAddressString(query)
        var seen = Set<String>()
        var matches: [RemoteCityMatch] = []

        for placemark in placemarks {
            guard
                let timeZoneID = placemark.timeZone?.identifier,
                let descriptor = TimeZoneDescriptor(identifier: timeZoneID)
            else {
                continue
            }

            let titleCandidates: [String?] = [
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
                placemark.name?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines),
                descriptor.city
            ]
            let title = titleCandidates
                .compactMap { $0 }
                .first(where: { $0.isEmpty == false }) ?? descriptor.city

            let subtitleCandidates: [String?] = [
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
                placemark.country
            ]
            let subtitleComponents = subtitleCandidates
                .compactMap { $0 }
                .filter { $0.isEmpty == false && $0 != title }

            let subtitle = subtitleComponents.isEmpty
                ? descriptor.locationLine
                : Array(NSOrderedSet(array: subtitleComponents))
                    .compactMap { $0 as? String }
                    .joined(separator: " • ")

            let match = RemoteCityMatch(
                title: title,
                subtitle: subtitle,
                timeZoneID: timeZoneID
            )
            guard seen.insert(match.id).inserted else {
                continue
            }
            matches.append(match)
        }

        return Array(matches.prefix(8))
    }
}
