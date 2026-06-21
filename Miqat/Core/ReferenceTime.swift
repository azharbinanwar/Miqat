import SwiftUI

enum ReferenceTime: String, CaseIterable, Identifiable, Codable {
    case fajr    = "Fajr"
    case sunrise = "Shuruq"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var id: String { rawValue }

    // Today-based getters — used everywhere except MonthlyView
    var label: String { label(for: Date()) }
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
    var color: Color  { color(for: Date()) }

    // Date-specific functions — used only in MonthlyView
    func label(for date: Date) -> String {
        self == .dhuhr && Calendar.current.component(.weekday, from: date) == 6
            ? "Jumu'ah" : rawValue
    }

    func color(for date: Date) -> Color {
        switch self {
        case .fajr:    return AppColor.fajr
        case .sunrise: return AppColor.sunrise
        case .dhuhr:   return Calendar.current.component(.weekday, from: date) == 6
                              ? AppColor.accentGreen : AppColor.dhuhr
        case .asr:     return AppColor.asr
        case .maghrib: return AppColor.maghrib
        case .isha:    return AppColor.isha
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

    var gradient: [Color] {
        switch self {
        case .fajr:    return [AppColor.deepNavy,    color]
        case .sunrise: return [AppColor.burntOrange, color]
        case .dhuhr:   return [AppColor.deepTeal,    color]
        case .asr:     return [AppColor.burntOrange, color]
        case .maghrib: return [AppColor.deepRed,     color]
        case .isha:    return [AppColor.deepNavy,    color]
        }
    }
}
