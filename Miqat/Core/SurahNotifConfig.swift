import SwiftUI

// MARK: - Kahf Anchor

enum KahfAnchor: String, CaseIterable, Codable, Identifiable {
    case thurMaghrib = "Thu Maghrib"
    case thurIsha    = "Thu Isha"
    case friFajr     = "Fri Fajr"
    case friDhuhr    = "Fri Dhuhr"
    case friAsr      = "Fri Asr"
    case customTime  = "Custom Time"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .thurMaghrib: return "Start of Islamic Friday"
        case .thurIsha:    return "Before sleep, Thursday"
        case .friFajr:     return "Friday morning"
        case .friDhuhr:    return "After Jumu'ah"
        case .friAsr:      return "Friday afternoon"
        case .customTime:  return "Fixed time on Friday"
        }
    }

    var icon: String {
        switch self {
        case .thurMaghrib: return "sunset.fill"
        case .thurIsha:    return "moon.stars.fill"
        case .friFajr:     return "sunrise.fill"
        case .friDhuhr:    return "sun.max.fill"
        case .friAsr:      return "sun.haze.fill"
        case .customTime:  return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .thurMaghrib: return ReferenceTime.maghrib.color
        case .thurIsha:    return ReferenceTime.isha.color
        case .friFajr:     return ReferenceTime.fajr.color
        case .friDhuhr:    return ReferenceTime.dhuhr.color
        case .friAsr:      return ReferenceTime.asr.color
        case .customTime:  return AppColor.accentGold
        }
    }

    var hasOffset: Bool { self != .customTime }
}

// MARK: - Kahf Anchor Config

struct KahfAnchorConfig: Identifiable, Codable, Equatable {
    var id: String { anchor.rawValue }
    let anchor: KahfAnchor
    var enabled: Bool
    var minutesAfter: Int   // 5–120, ignored when anchor == .customTime
    var fixedTime: Date?    // only used when anchor == .customTime
    var sound: AppSound
}

// MARK: - Surah Mulk Config

struct SurahMulkConfig: Codable, Equatable {
    var enabled: Bool = false
    var minutesAfterIsha: Int = 30   // 5–120
    var sound: AppSound = .systemDefault
}

// MARK: - Surah Kahf Config

struct SurahKahfConfig: Codable {
    var anchors: [KahfAnchorConfig] = KahfAnchor.allCases.map { anchor in
        KahfAnchorConfig(
            anchor: anchor,
            enabled: false,
            minutesAfter: 15,
            fixedTime: nil,
            sound: .systemDefault
        )
    }
}

// MARK: - Friday Jumu'ah Config

struct FridayJumuahConfig: Codable, Equatable {
    var enabled: Bool       = false
    var xMinutes: Int       = 20    // 5–60, remind before Jumu'ah
    var zMinutes: Int       = 30    // 5–60, khutbah starts after Dhuhr
    var missedEnabled: Bool = false // remind later if missed
    var missedMinutes: Int  = 30    // 5–120, how long after to remind
    var sound: AppSound     = .systemDefault
}
