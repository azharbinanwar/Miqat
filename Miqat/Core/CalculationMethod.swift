import Foundation

enum CalculationMethod: String, CaseIterable, Codable, Identifiable {
    case mwl          = "mwl"
    case isna         = "isna"
    case egypt        = "egypt"
    case makkah       = "makkah"
    case karachi      = "karachi"
    case turkey       = "turkey"
    case moonsighting = "moonsighting"
    case singapore    = "singapore"
    case dubai        = "dubai"
    case tehran       = "tehran"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mwl:          return "Muslim World League"
        case .isna:         return "ISNA (North America)"
        case .egypt:        return "Egyptian Authority"
        case .makkah:       return "Umm al-Qura (Makkah)"
        case .karachi:      return "Karachi (Pakistan)"
        case .turkey:       return "Diyanet (Turkey)"
        case .moonsighting: return "Moonsighting Committee"
        case .singapore:    return "MUIS (Singapore)"
        case .dubai:        return "Dubai (UAE)"
        case .tehran:       return "Tehran (Iran)"
        }
    }

    var region: String {
        switch self {
        case .mwl:          return "Europe, Africa, Far East"
        case .isna:         return "North America"
        case .egypt:        return "Egypt, Africa"
        case .makkah:       return "Saudi Arabia"
        case .karachi:      return "Pakistan, India, Bangladesh"
        case .turkey:       return "Turkey"
        case .moonsighting: return "Global"
        case .singapore:    return "Singapore, SE Asia"
        case .dubai:        return "UAE"
        case .tehran:       return "Iran"
        }
    }

    var fajrAngle: Double {
        switch self {
        case .mwl:          return 18.0
        case .isna:         return 15.0
        case .egypt:        return 19.5
        case .makkah:       return 18.5
        case .karachi:      return 18.0
        case .turkey:       return 18.0
        case .moonsighting: return 0.0
        case .singapore:    return 20.0
        case .dubai:        return 18.0
        case .tehran:       return 17.5
        }
    }

    var ishaAngle: Double? {
        switch self {
        case .mwl:          return 17.0
        case .isna:         return 15.0
        case .egypt:        return 17.5
        case .makkah:       return nil
        case .karachi:      return 18.0
        case .turkey:       return 17.0
        case .moonsighting: return nil
        case .singapore:    return 18.0
        case .dubai:        return 18.0
        case .tehran:       return 14.0
        }
    }

    var ishaOffsetMinutes: Int? {
        switch self {
        case .makkah: return 90
        default:      return nil
        }
    }

    var icon: String {
        switch self {
        case .mwl:          return "globe.europe.africa.fill"
        case .isna:         return "globe.americas.fill"
        case .egypt:        return "pyramid.fill"
        case .makkah:       return "building.columns.fill"
        case .karachi:      return "flag.fill"
        case .turkey:       return "crescent.fill"
        case .moonsighting: return "moon.stars.fill"
        case .singapore:    return "ferry.fill"
        case .dubai:        return "building.2.fill"
        case .tehran:       return "star.and.crescent"
        }
    }

    var angleDescription: String {
        if self == .moonsighting {
            return "Sighting-based"
        }
        var parts: [String] = []
        parts.append("Fajr \(String(format: "%.1f", fajrAngle))°")
        if let offset = ishaOffsetMinutes {
            parts.append("Isha Maghrib +\(offset)m")
        } else if let angle = ishaAngle {
            parts.append("Isha \(String(format: "%.1f", angle))°")
        }
        return parts.joined(separator: " · ")
    }

    var detailTiles: [(label: String, value: String)] {
        if self == .moonsighting {
            return [("Fajr", "Sighting"), ("Isha", "Sighting"), ("Region", region)]
        }
        var tiles: [(label: String, value: String)] = []
        tiles.append(("Fajr angle", "\(String(format: "%.1f", fajrAngle))°"))
        if let offset = ishaOffsetMinutes {
            tiles.append(("Isha offset", "\(offset) min after Maghrib"))
        } else if let angle = ishaAngle {
            tiles.append(("Isha angle", "\(String(format: "%.1f", angle))°"))
        }
        tiles.append(("Region", region))
        return tiles
    }
}
