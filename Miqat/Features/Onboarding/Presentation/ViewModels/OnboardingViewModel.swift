import SwiftUI

@Observable
final class OnboardingViewModel {
    var page           : Int    = 0
    var selectedMadhab : Madhab = .hanafi
    var notifRequested : Bool   = false
    var showSearch     : Bool   = false

    let locationVM = LocationViewModel.shared

    enum GPSState { case idle, detecting, done, denied, failed }

    var gpsState: GPSState {
        switch locationVM.fetchState {
        case .idle:                  return .idle
        case .requesting, .fetching: return .detecting
        case .done:                  return .done
        case .denied:                return .denied
        case .failed:                return .failed
        }
    }

    var isBlocked    : Bool { page == 3 && gpsState == .detecting }
    var isLastPage   : Bool { page == 3 }
    var isNotifPage  : Bool { page == 2 }

    var ctaLabel: String {
        switch page {
        case 2:  return "Allow Notifications"
        case 3:  return "Start Praying"
        default: return "Continue"
        }
    }

    var ctaIcon: String {
        switch page {
        case 2:  return "bell.badge.fill"
        case 3:  return "checkmark"
        default: return "arrow.right"
        }
    }

    func skipNotifications() async {
        withAnimation(.spring(duration: 0.4)) { page = 3 }
    }

    func advance() async {
        if page == 1 {
            UserDefaults.standard.set(selectedMadhab.rawValue, forKey: Keys.Defaults.selectedMadhab)
        }
        if page == 2 {
            await NotificationManager.shared.requestPermission()
            notifRequested = true
            try? await Task.sleep(for: .milliseconds(400))
        }
        withAnimation(.spring(duration: 0.4)) {
            page = min(page + 1, 3)
        }
    }

    var pageGradient: LinearGradient {
        switch page {
        case 0: return LinearGradient(
            colors: [Color(hex: "#0F172A"), Color(hex: "#1E1B4B"), Color(hex: "#4C1D95")],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(
            colors: [Color(hex: "#78350F"), Color(hex: "#D97706")],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(
            colors: [Color(hex: "#14532D"), Color(hex: "#0D9488")],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(
            colors: [Color(hex: "#0F766E"), Color(hex: "#0284C7")],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var ctaTextColor: Color {
        switch page {
        case 0: return Color(hex: "#4C1D95")
        case 1: return Color(hex: "#78350F")
        case 2: return Color(hex: "#14532D")
        default: return Color(hex: "#0F766E")
        }
    }
}
