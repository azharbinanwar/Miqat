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
            _ = await NotificationManager.shared.requestPermission()
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
            colors: [AppColor.deepNavy, AppColor.darkNavy, AppColor.purple],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        case 1: return LinearGradient(
            colors: [AppColor.brown, AppColor.asr],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(
            colors: [AppColor.green, AppColor.accentTeal],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(
            colors: [AppColor.deepTeal, AppColor.skyCyan],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var ctaTextColor: Color {
        switch page {
        case 0: return AppColor.purple
        case 1: return AppColor.brown
        case 2: return AppColor.green
        default: return AppColor.deepTeal
        }
    }
}
