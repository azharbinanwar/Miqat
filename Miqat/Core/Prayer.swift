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
    let id: UUID
    var referenceTime: ReferenceTime
    let time: String
    let date: Date?        // Raw Date from Adhan for countdown / scheduling
    let madhab: String
    var status: PrayerStatus
    var isCurrent: Bool = false
    var isAlert: Bool = false
}

extension PrayerEntry {
    var timeStatus: PrayerTimeStatus {
        if isCurrent || status == .current { return .current }
        if isAlert   || status == .alert   { return .soon }
        if status == .passed               { return .passed }
        return .upcoming
    }

    var trackerStatus: PrayerTrackerStatus {
        status == .prayed ? .prayed : .pending
    }
}

extension PrayerEntry {
    static func mock(
        referenceTime: ReferenceTime,
        time: String,
        date: Date? = nil,
        madhab: String = "Hanafi",
        status: PrayerStatus = .upcoming,
        isCurrent: Bool = false,
        isAlert: Bool = false
    ) -> PrayerEntry {
        PrayerEntry(
            id: UUID(),
            referenceTime: referenceTime,
            time: time,
            date: date,
            madhab: madhab,
            status: status,
            isCurrent: isCurrent,
            isAlert: isAlert
        )
    }
}
