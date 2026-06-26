import SwiftUI

enum PrayerTimeStatus: String, Codable {
    case current  = "Now"
    case soon     = "Soon"
    case upcoming = "Upcoming"

    var label: String { rawValue }

    var badgeLabel: String? {
        switch self {
        case .current:  return "NOW"
        case .soon:     return "SOON"
        case .upcoming: return "Upcoming"
        }
    }

    var badgeColor: Color {
        switch self {
        case .soon:    return AppColor.softAmber
        default:       return .white
        }
    }

    var icon: String {
        switch self {
        case .current:  return "clock.fill"
        case .soon:     return "exclamationmark.circle.fill"
        case .upcoming: return "circle"
        }
    }
}
