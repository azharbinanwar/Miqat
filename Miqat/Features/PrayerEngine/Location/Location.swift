import CoreLocation

struct Location: Identifiable, Codable, Equatable {
    var id        = UUID()
    var label     : String
    var icon      : String
    var city      : String
    var latitude  : Double
    var longitude : Double
    var timezone  : String = TimeZone.current.identifier

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: Location, rhs: Location) -> Bool { lhs.id == rhs.id }

    // MARK: - Presets (seed cities — non-deleteable)
    static let makkah  = Location(label: "Makkah",  icon: "building.columns.fill",
                                   city: "Makkah, Saudi Arabia",
                                   latitude: 21.3891, longitude: 39.8579,
                                   timezone: "Asia/Riyadh")

    static let madinah = Location(label: "Madinah", icon: "building.columns.fill",
                                   city: "Madinah, Saudi Arabia",
                                   latitude: 24.5247, longitude: 39.5692,
                                   timezone: "Asia/Riyadh")

    static let karachi = Location(label: "Karachi", icon: "building.2.fill",
                                   city: "Karachi, Pakistan",
                                   latitude: 24.8607, longitude: 67.0011,
                                   timezone: "Asia/Karachi")

    static let presets: [Location] = [.makkah, .madinah, .karachi]
    static let presetLabels: Set<String> = ["Makkah", "Madinah", "Karachi"]
    static let defaultLocation: Location = .makkah
}
