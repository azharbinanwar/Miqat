import SwiftUI

// MARK: - Prayer (main type — icon, color, gradient, label)

enum Prayer: String, CaseIterable, Identifiable, Codable {
    case fajr    = "Fajr"
    case sunrise = "Shuruq"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var id: String { rawValue }

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
    var color: Color { color(for: Date()) }

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

    var onColor: Color {
        switch self {
        case .fajr:    return .white
        case .sunrise: return Color(hex: "#7C2D12")
        case .dhuhr:   return .white
        case .asr:     return Color(hex: "#7C2D12")
        case .maghrib: return .white
        case .isha:    return .white
        }
    }

    var fajrAngle: Double?  { self == .fajr ? 18.0 : nil }
    var ishaAngle: Double?  { self == .isha ? 18.0 : nil }
    var isPrayer:  Bool     { self != .sunrise }

    var gradient: [Color] {
        switch self {
        case .fajr:    return [AppColor.deepNavy,    color]           // near black → indigo
        case .sunrise: return [AppColor.burntOrange, color]           // deep red-brown → warm orange
        case .dhuhr:   return [AppColor.deepTeal,    color]           // deep sky → bright blue
        case .asr:     return [AppColor.burntOrange, color]           // deep brown → golden amber
        case .maghrib: return [AppColor.deepRed,     color]           // deep crimson → rose red
        case .isha:    return [AppColor.deepNavy,    AppColor.darkNavy] // near black → deep indigo
        }
    }
}

// MARK: - PrayerEntry (a calculated prayer slot for a given day)

struct PrayerEntry: Identifiable, Codable {
    let id: UUID
    var prayer: Prayer
    let time: String
    let date: Date?
    var status: PrayerTimeStatus
    var isCurrent: Bool = false
}

extension PrayerEntry {
    var label: String { prayer.label }
    var icon:  String { prayer.icon }
    var color: Color  { prayer.color }

    var isPast: Bool {
        guard let date else { return false }
        return date < Date()
    }
}

extension PrayerEntry {
    static func mock(
        prayer: Prayer,
        time: String,
        date: Date? = nil,
        status: PrayerTimeStatus = .upcoming,
        isCurrent: Bool = false
    ) -> PrayerEntry {
        PrayerEntry(id: UUID(), prayer: prayer, time: time, date: date,
                    status: status, isCurrent: isCurrent)
    }
}
