import SwiftUI

enum PrayerTimeStatus: String, Codable {
    case current  = "Now"
    case soon     = "Soon"
    case upcoming = "Upcoming"
    case passed   = "Passed"

    var badgeLabel: String? {
        switch self {
        case .current:  return "NOW"
        case .soon:     return "SOON"
        default:        return nil
        }
    }

    var icon: String {
        switch self {
        case .current:  return "clock.fill"
        case .soon:     return "exclamationmark.circle.fill"
        case .upcoming: return "circle"
        case .passed:   return "minus.circle"
        }
    }

    var badgeColor: Color {
        switch self {
        case .soon:    return AppColor.softAmber
        default:       return .white
        }
    }
}
