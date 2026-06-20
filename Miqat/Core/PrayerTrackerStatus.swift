import SwiftUI

enum PrayerTrackerStatus: String, Codable {
    case prayed  = "Prayed"
    case missed  = "Missed"
    case pending = "Pending"

    var badgeLabel: String? {
        switch self {
        case .prayed:  return "PRAYED"
        case .missed:  return "MISSED"
        case .pending: return nil
        }
    }

    var icon: String {
        switch self {
        case .prayed:  return "checkmark.circle.fill"
        case .missed:  return "xmark.circle"
        case .pending: return "circle.dotted"
        }
    }

    var color: Color {
        switch self {
        case .prayed:  return AppColor.softGreen
        case .missed:  return AppColor.softRed
        case .pending: return .white.opacity(0.3)
        }
    }

    var badgeBackground: Color {
        switch self {
        case .prayed:  return AppColor.softGreen.opacity(0.18)
        case .missed:  return AppColor.softRed.opacity(0.18)
        case .pending: return .clear
        }
    }
}
