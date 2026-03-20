import AnyTimeCore
import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationTimeZoneMonitor: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private(set) var currentTimeZoneID: String?
    private(set) var currentCityName: String?
    private var shouldRefreshWhenAuthorized = false
    private var lastGeocodedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 5_000
    }

    func refreshIfAuthorized() {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            resolveCurrentLocation()
        case .notDetermined, .denied, .restricted:
            return
        @unknown default:
            return
        }
    }

    func requestCurrentLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            shouldRefreshWhenAuthorized = true
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            resolveCurrentLocation()
        case .denied, .restricted:
            return
        @unknown default:
            return
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard shouldRefreshWhenAuthorized else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            shouldRefreshWhenAuthorized = false
            resolveCurrentLocation()
        case .denied, .restricted:
            shouldRefreshWhenAuthorized = false
        case .notDetermined:
            break
        @unknown default:
            shouldRefreshWhenAuthorized = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }

        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    private func resolveCurrentLocation() {
        if let location = manager.location {
            reverseGeocode(location)
            return
        }

        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        if let lastGeocodedLocation, location.distance(from: lastGeocodedLocation) < 5_000 {
            return
        }

        lastGeocodedLocation = location
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard
                let self,
                let placemark = placemarks?.first,
                let timeZoneID = placemark.timeZone?.identifier
            else {
                return
            }

            Task { @MainActor in
                self.currentTimeZoneID = timeZoneID
                self.currentCityName = placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.name
                    ?? TimeZoneDescriptor(identifier: timeZoneID)?.city
            }
        }
    }
}
