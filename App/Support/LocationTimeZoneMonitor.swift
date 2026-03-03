import Foundation
import Observation

#if canImport(CoreLocation)
import CoreLocation

@MainActor
@Observable
final class LocationTimeZoneMonitor: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private(set) var currentTimeZoneID: String?
    private var isTrackingEnabled = false
    private var lastGeocodedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 5_000
    }

    func setTrackingEnabled(_ enabled: Bool) {
        isTrackingEnabled = enabled

        guard enabled else {
            manager.stopUpdatingLocation()
            geocoder.cancelGeocode()
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            if let location = manager.location {
                reverseGeocode(location)
            }
        case .denied, .restricted:
            manager.stopUpdatingLocation()
        @unknown default:
            manager.stopUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isTrackingEnabled else {
            return
        }

        setTrackingEnabled(true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTrackingEnabled, let location = locations.last else {
            return
        }

        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    private func reverseGeocode(_ location: CLLocation) {
        if let lastGeocodedLocation, location.distance(from: lastGeocodedLocation) < 5_000 {
            return
        }

        lastGeocodedLocation = location
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard
                let self,
                let timeZoneID = placemarks?.first?.timeZone?.identifier
            else {
                return
            }

            Task { @MainActor in
                self.currentTimeZoneID = timeZoneID
            }
        }
    }
}
#else
@MainActor
@Observable
final class LocationTimeZoneMonitor {
    private(set) var currentTimeZoneID: String?

    func setTrackingEnabled(_ enabled: Bool) {}
}
#endif
