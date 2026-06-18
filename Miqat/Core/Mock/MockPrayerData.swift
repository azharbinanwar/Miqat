import SwiftUI

// MARK: - Global Madhab constant (used in UI, DB, PrayerEngine)
enum Madhab: String, CaseIterable, Codable {
    case hanafi  = "Hanafi"
    case shafi   = "Shafi'i"
}

enum Prayer: String, CaseIterable {
    case fajr    = "Fajr"
    case sunrise = "Sunrise"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var icon: String {
        switch self {
        case .fajr:    return "moon.fill"
        case .sunrise: return "sunrise.fill"
        case .dhuhr:   return "sun.max.fill"
        case .asr:     return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha:    return "moon.stars.fill"
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
}

enum PrayerStatus: String {
    case prayed   = "Prayed"
    case passed   = "Passed"
    case current  = "Coming up"
    case upcoming = "Upcoming"
    case alert    = "Soon"
}

struct PrayerEntry: Identifiable {
    let id = UUID()
    let prayer: Prayer
    let time: String
    let madhab: String
    let status: PrayerStatus
    var isCurrent: Bool = false
    var isAlert: Bool = false
}

enum MockPrayerData {
    static let entries: [PrayerEntry] = [
        PrayerEntry(prayer: .fajr,    time: "4:18 AM",  madhab: "Hanafi", status: .prayed),
        PrayerEntry(prayer: .sunrise, time: "5:47 AM",  madhab: "Hanafi", status: .passed),
        PrayerEntry(prayer: .dhuhr,   time: "12:08 PM", madhab: "Hanafi", status: .prayed),
        PrayerEntry(prayer: .asr,     time: "4:42 PM",  madhab: "Hanafi", status: .current,  isCurrent: true),
        PrayerEntry(prayer: .maghrib, time: "7:21 PM",  madhab: "Hanafi", status: .alert,    isAlert: true),
        PrayerEntry(prayer: .isha,    time: "8:54 PM",  madhab: "Hanafi", status: .upcoming),
    ]

    static let nextPrayer     = "Asr"
    static let nextPrayerTime = "4:42 PM"
    static let countdown      = "1:24"
    static let hijriDate      = "21 Dhul Hijjah 1447"
    static let fullDate       = "Thursday, 18 June 2026"
    static let location       = "Lahore, PK"
    static let streak         = 12
    static let todayPrayed    = 2
    static let todayTotal     = 5
    static let sunrise        = "5:47 AM"
    static let sunset         = "7:21 PM"
}
