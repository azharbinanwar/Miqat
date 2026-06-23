import Foundation

enum PrayerTrackerStatus: String, Codable, CaseIterable {
    case upcoming     = "upcoming"
    case prayedOnTime = "prayedOnTime"
    case prayedKaza   = "prayedKaza"
    case missed       = "missed"

    var label: String {
        switch self {
        case .upcoming:     return "Upcoming"
        case .prayedOnTime: return "Prayed on time"
        case .prayedKaza:   return "Prayed Kaza"
        case .missed:       return "Missed"
        }
    }
}
