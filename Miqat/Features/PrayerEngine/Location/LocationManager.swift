import AppKit
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authStatus : CLAuthorizationStatus   = .notDetermined
    @Published private(set) var coordinate : CLLocationCoordinate2D? = nil
    @Published private(set) var cityName   : String                  = ""

    private let manager  = CLLocationManager()
    private let geocoder = CLGeocoder()

    var isAuthorized: Bool { authStatus == .authorizedAlways || authStatus == .authorized }
    var isDenied: Bool     { authStatus == .denied || authStatus == .restricted }

    override init() {
        super.init()
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        authStatus = manager.authorizationStatus
    }

    func requestPermission() {
        DispatchQueue.main.async { self.manager.requestWhenInUseAuthorization() }
    }

    func requestLocation() {
        coordinate = nil
        DispatchQueue.main.async { self.manager.startUpdatingLocation() }
    }

    func stopUpdatesOnly() {
        manager.stopUpdatingLocation()
    }

    func cancelAll() {
        manager.stopUpdatingLocation()
        geocoder.cancelGeocode()
    }

    // MARK: - Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authStatus = manager.authorizationStatus }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        manager.stopUpdatingLocation()
        DispatchQueue.main.async { self.coordinate = loc.coordinate }
        reverseGeocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        if code == .denied || code == .regionMonitoringDenied {
            manager.stopUpdatingLocation()
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let place = placemarks?.first else { return }
            let city    = place.locality ?? place.administrativeArea ?? ""
            let country = place.country ?? ""
            let name    = [city, country].filter { !$0.isEmpty }.joined(separator: ", ")
            DispatchQueue.main.async { self?.cityName = name }
        }
    }
}
