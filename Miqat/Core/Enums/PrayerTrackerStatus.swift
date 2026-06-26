import Foundation
import SwiftUI

enum PrayerTrackerStatus: String, Codable, CaseIterable {
    case prayedOnTime      = "prayedOnTime"
    case prayedWithJamaat  = "prayedWithJamaat"
    case prayedKaza        = "prayedKaza"
    case missed            = "missed"

    var label: String {
        switch self {
        case .prayedOnTime:     return "Prayed on time"
        case .prayedWithJamaat: return "Prayed with Jamaat"
        case .prayedKaza:       return "Prayed Kaza"
        case .missed:           return "Missed"
        }
    }

    var shortLabel: String {
        switch self {
        case .prayedOnTime:     return "Prayed"
        case .prayedWithJamaat: return "Jamaat"
        case .prayedKaza:       return "Kaza"
        case .missed:           return "Missed"
        }
    }

    var icon: String {
        switch self {
        case .prayedOnTime:     return "checkmark.circle.fill"
        case .prayedWithJamaat: return "person.2.circle.fill"
        case .prayedKaza:       return "clock.arrow.circlepath"
        case .missed:           return "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .prayedOnTime:     return Color(hex: "#22C55E")
        case .prayedWithJamaat: return Color(hex: "#3B82F6")
        case .prayedKaza:       return Color(hex: "#F59E0B")
        case .missed:           return Color(hex: "#EF4444")
        }
    }

    var keepsStreak: Bool {
        switch self {
        case .prayedOnTime, .prayedWithJamaat, .prayedKaza: return true
        case .missed: return false
        }
    }
}
