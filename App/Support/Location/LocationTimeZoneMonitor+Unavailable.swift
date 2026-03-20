import Foundation
import Observation

#if !canImport(CoreLocation)
@MainActor
@Observable
final class LocationTimeZoneMonitor {
    private(set) var currentTimeZoneID: String?
    private(set) var currentCityName: String?

    func refreshIfAuthorized() {}

    func requestCurrentLocation() {}
}
#endif
