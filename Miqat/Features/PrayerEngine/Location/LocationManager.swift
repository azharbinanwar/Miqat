import AppKit
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    @Published private(set) var authStatus : CLAuthorizationStatus   = .notDetermined
    @Published private(set) var coordinate : CLLocationCoordinate2D? = nil
    @Published private(set) var cityName   : String                  = ""

    private let manager  = CLLocationManager()
    private let geocoder = CLGeocoder()

    var isAuthorized: Bool { authStatus == .authorizedAlways || authStatus == .authorized }
    var isDenied: Bool     { authStatus == .denied || authStatus == .restricted }

    private override init() {
        super.init()
        manager.delegate        = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        authStatus = manager.authorizationStatus
        print("[LocationManager] init — status: \(authStatus.rawValue)")
    }

    func requestPermission() {
        print("[LocationManager] requestPermission")
        DispatchQueue.main.async { self.manager.requestWhenInUseAuthorization() }
    }

    func requestLocation() {
        print("[LocationManager] requestLocation — startUpdatingLocation")
        coordinate = nil
        DispatchQueue.main.async { self.manager.startUpdatingLocation() }
    }

    func stopUpdatesOnly() {
        manager.stopUpdatingLocation()
        print("[LocationManager] stopped updates")
    }

    func cancelAll() {
        manager.stopUpdatingLocation()
        geocoder.cancelGeocode()
        print("[LocationManager] stopped updates + geocoding")
    }

    // MARK: - Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let s = manager.authorizationStatus
        print("[LocationManager] auth changed — status: \(s.rawValue)")
        DispatchQueue.main.async { self.authStatus = s }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        print("[LocationManager] got location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        // Stop continuous updates — we only need one fix
        manager.stopUpdatingLocation()
        DispatchQueue.main.async { self.coordinate = loc.coordinate }
        reverseGeocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        print("[LocationManager] error: \(error.localizedDescription) — code: \(String(describing: code))")
        // locationUnknown is transient — startUpdatingLocation() will keep retrying automatically
        // Only stop on a hard failure (denied, network unavailable, etc.)
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
            print("[LocationManager] city resolved: \(name) — mainWindow exists: \(NSApp.mainWindow != nil)")
            DispatchQueue.main.async { self?.cityName = name }
        }
    }
}
