import SwiftUI
import ServiceManagement

@Observable
final class OnboardingViewModel {
    var page           : Int    = 0
    var selectedMadhab : Madhab = .hanafi
    var notifRequested        : Bool   = false
    var loginItemRequested    : Bool   = false
    var loginItemNeedsApproval: Bool   = false
    var showSearch            : Bool   = false

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
    var isLastPage   : Bool { page == 4 }
    var isLoginPage  : Bool { page == 4 }
    var isNotifPage  : Bool { page == 2 }

    var ctaLabel: String {
        switch page {
        case 2:  return "Allow Notifications"
        case 3:  return "Start Praying"
        case 4:  return (loginItemRequested || loginItemNeedsApproval) ? "Continue" : "Enable at Login"
        default: return "Continue"
        }
    }

    var ctaIcon: String {
        switch page {
        case 2:  return "bell.badge.fill"
        case 3:  return "checkmark"
        case 4:  return loginItemRequested ? "checkmark" : "power"
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
            page = min(page + 1, 4)
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
        case 4: return LinearGradient(
            colors: [AppColor.purple, AppColor.deepNavy],
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
        case 4: return AppColor.purple
        default: return AppColor.deepTeal
        }
    }

    private(set) var didEnableLoginItem = false

    func requestLoginItem() async {
        do {
            try SMAppService.mainApp.register()
            loginItemRequested = true
            didEnableLoginItem = true
            try? await Task.sleep(for: .milliseconds(400))
        } catch {
            loginItemNeedsApproval = true
        }
    }
}
