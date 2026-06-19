import SwiftUI

enum Prayer: String, CaseIterable, Identifiable, Codable {
    case fajr    = "Fajr"
    case dhuhr   = "Dhuhr"
    case asr     = "Asr"
    case maghrib = "Maghrib"
    case isha    = "Isha"

    var id: String { rawValue }

    var referenceTime: ReferenceTime {
        switch self {
        case .fajr:    return .fajr
        case .dhuhr:   return .dhuhr
        case .asr:     return .asr
        case .maghrib: return .maghrib
        case .isha:    return .isha
        }
    }

    var label: String { referenceTime.label }
    var icon:  String { referenceTime.icon }
    var color: Color  { referenceTime.color }
}

enum PrayerStatus: String, Codable {
    case prayed   = "Prayed"
    case passed   = "Passed"
    case current  = "Coming up"
    case upcoming = "Upcoming"
    case alert    = "Soon"
}

struct PrayerEntry: Identifiable, Codable {
    let id = UUID()
    var referenceTime: ReferenceTime
    let time: String
    let madhab: String
    let status: PrayerStatus
    var isCurrent: Bool = false
    var isAlert: Bool = false
}
