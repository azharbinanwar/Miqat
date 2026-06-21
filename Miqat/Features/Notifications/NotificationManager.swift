import Foundation
import UserNotifications
import AppKit

@Observable
final class NotificationManager {

    enum PermissionState {
        case unknown, granted, denied
    }

    var permissionState: PermissionState = .unknown

    static let shared = NotificationManager()
    private init() {}

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional: permissionState = .granted
            case .denied:                   permissionState = .denied
            default:                        permissionState = .unknown
            }
        }
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                permissionState = granted ? .granted : .denied
            }
        } catch {
            await MainActor.run { permissionState = .denied }
        }
    }

    // Called when user taps "Open Settings" — re-checks when app becomes active again
    func startListeningForPermissionChange() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.checkPermission() }
            // Stop listening once granted
            if self.permissionState == .granted {
                self.stopListeningForPermissionChange()
            }
        }
    }

    func stopListeningForPermissionChange() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func sendTestNotification(prayerName: String, sound: AppSound = .systemDefault, customSoundFilename: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "\(prayerName) — Test"
        content.body  = "Notifications are working correctly."
        content.sound = .default
        var userInfo: [String: String] = ["soundName": sound.rawValue]
        if let filename = customSoundFilename { userInfo["customSoundFilename"] = filename }
        content.userInfo = userInfo
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test.\(prayerName)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
