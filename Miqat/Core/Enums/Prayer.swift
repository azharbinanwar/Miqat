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

    var fajrAngle: Double?  { self == .fajr ? 18.0 : nil }
    var ishaAngle: Double?  { self == .isha ? 18.0 : nil }
    var isPrayer:  Bool     { self != .sunrise }

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

// MARK: - PrayerStatus (live display state for today's list)

enum PrayerStatus: String, Codable {
    case prayed   = "Prayed"
    case passed   = "Passed"
    case current  = "Coming up"
    case upcoming = "Upcoming"
    case alert    = "Soon"
}

// MARK: - PrayerEntry (a calculated prayer slot for a given day)

struct PrayerEntry: Identifiable, Codable {
    let id: UUID
    var prayer: Prayer
    let time: String
    let date: Date?
    let madhab: String
    var status: PrayerStatus
    var isCurrent: Bool = false
    var isAlert: Bool   = false
}

extension PrayerEntry {
    var label: String { prayer.label }
    var icon:  String { prayer.icon }
    var color: Color  { prayer.color }
}

extension PrayerEntry {
    var timeStatus: PrayerTimeStatus {
        if isCurrent || status == .current { return .current }
        if isAlert   || status == .alert   { return .soon }
        if status == .passed               { return .passed }
        return .upcoming
    }
}

extension PrayerEntry {
    static func mock(
        prayer: Prayer,
        time: String,
        date: Date? = nil,
        madhab: String = "Hanafi",
        status: PrayerStatus = .upcoming,
        isCurrent: Bool = false,
        isAlert: Bool = false
    ) -> PrayerEntry {
        PrayerEntry(id: UUID(), prayer: prayer, time: time, date: date,
                    madhab: madhab, status: status, isCurrent: isCurrent, isAlert: isAlert)
    }
}
