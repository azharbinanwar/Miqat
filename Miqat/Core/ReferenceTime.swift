import SwiftUI

enum ReferenceTime: String, CaseIterable, Identifiable, Codable {
    case fajr    = "Fajr"
    case sunrise = "Shuruq"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var id: String    { rawValue }
    var label: String { rawValue }

    var icon: String {
        switch self {
        case .fajr:    return "moon.stars.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .fajr:    return Color(hex: "#7C3AED")
        case .sunrise: return Color(hex: "#F59E0B")
        case .dhuhr:   return Color(hex: "#F59E0B")
        case .asr:     return Color(hex: "#0D9488")
        case .maghrib: return Color(hex: "#DC2626")
        case .isha:    return Color(hex: "#7C3AED")
        }
    }

    var fajrAngle: Double? {
        switch self {
        case .fajr: return 18.0
        default:    return nil
        }
    }

    var ishaAngle: Double? {
        switch self {
        case .isha: return 18.0
        default:    return nil
        }
    }

    var isPrayer: Bool { self != .sunrise }
}
