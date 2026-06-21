import AppKit
import AVFoundation
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Surfaces
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindowController: NSWindowController?
    private var widgetController: NSWindowController?
    private var onboardingWindow: NSWindow?
    private var menuBarVM     : PrayerTimeViewModel!
    private var settingsVM    : SettingsViewModel!
    private var locationVM    : LocationViewModel!
    private var notificationVM: NotificationViewModel!
    private var statusTimer   : Timer?
    private var wakeObserver  : Any?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().delegate = self
        setupDI()
        setupPrayerTimes()
        setupStatusItem()
        setupPopover()

        if UserDefaults.standard.bool(forKey: Keys.Defaults.hasCompletedOnboarding) {
            showMainWindow()
        } else {
            showOnboarding()
        }
    }

    // MARK: - Prayer Times (shared for Menu Bar)

    private func setupPrayerTimes() {
        let repo = ServiceLocator.shared.resolve(LocationRepository.self)
        repo.seedIfEmpty()

        menuBarVM = PrayerTimeViewModel()
        menuBarVM.update(settings: settingsVM.settings.prayerCalculationSettings)
        if let location = repo.getActiveLocation() {
            menuBarVM.load(location: location)
        }
        // Wire location + settings into notification scheduler
        // Always use saved location — never wait for live GPS
        let savedLocation = repo.getActiveLocation()
        let activeLocation = savedLocation ?? Location.defaultLocation
        print("[AppDelegate] location: \(savedLocation != nil ? "saved=\(activeLocation.label)" : "nil — using default \(activeLocation.label)")")
        notificationVM.location = activeLocation
        notificationVM.calculationSettings = settingsVM.settings.prayerCalculationSettings
        notificationVM.rescheduleAll()

        menuBarVM.startLiveUpdates()

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            print("💻 Mac woke — running scheduleIfNeeded")
            self.notificationVM.rescheduleIfNeeded()
        }

        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let button = self?.statusItem?.button else { return }
            self?.updateStatusItemTitle(button: button)
        }
    }

    // MARK: - Status Item (menu bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        updateStatusItemTitle(button: button)
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func updateStatusItemTitle(button: NSStatusBarButton) {
        let s = settingsVM.settings

        let attrStr = NSMutableAttributedString()

        // Icon
        if s.menuShowIcon,
           let img = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: nil) {
            let attachment = NSTextAttachment()
            attachment.image = img
            attrStr.append(NSAttributedString(attachment: attachment))
            attrStr.append(NSAttributedString(string: " "))
        }

        // Prayer name
        if s.menuShowPrayerName {
            let name = menuBarVM.nextPrayerEntry?.label ?? "--"
            attrStr.append(NSAttributedString(string: "\(name) "))
        }

        // Display mode: countdown vs time
        switch s.menuDisplay {
        case .countdown:
            var countdown = menuBarVM.countdownText
            if !s.menuShowSeconds {
                countdown = stripSeconds(from: countdown)
            }
            attrStr.append(NSAttributedString(string: countdown))

            let mins = minutesRemaining(from: menuBarVM.countdownText)
            let warningColor: NSColor = mins <= s.redThreshold    ? NSColor(AppColor.alert) :
                                        mins <= s.orangeThreshold ? NSColor(AppColor.softAmber) :
                                        .labelColor
            let range = NSRange(location: 0, length: attrStr.length)
            attrStr.addAttribute(.foregroundColor, value: warningColor, range: range)
            attrStr.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium), range: range)

        case .nextTime:
            let timeText = menuBarVM.nextPrayerEntry?.time ?? "--:--"
            attrStr.append(NSAttributedString(string: timeText))
            let range = NSRange(location: 0, length: attrStr.length)
            attrStr.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
            attrStr.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium), range: range)
        }

        button.attributedTitle = attrStr
    }

    private func stripSeconds(from countdown: String) -> String {
        let parts = countdown.split(separator: ":")
        if parts.count == 3 { return "\(parts[0]):\(parts[1])" }
        if parts.count == 2 { return String(parts[0]) }
        return countdown
    }

    private func minutesRemaining(from countdown: String) -> Int {
        let parts = countdown.split(separator: ":").compactMap { Int($0) }
        switch parts.count {
        case 3: return parts[0] * 60 + parts[1]
        case 2: return parts[0]
        default: return 999
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentSize           = NSSize(width: 320, height: 480)
        pop.contentViewController = NSHostingController(rootView: PopoverView(prayerVM: menuBarVM, settingsVM: settingsVM))
        popover = pop
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let pop = popover else { return }

        if pop.isShown {
            pop.performClose(nil)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Main Window

    func showMainWindow() {
        if let existing = mainWindowController {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Miqat"
        window.titlebarAppearsTransparent = false
        window.center()
        window.contentView = NSHostingView(rootView: MainWindowView()
            .environment(settingsVM)
            .environment(menuBarVM)
            .environment(locationVM)
            .environment(notificationVM))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindowController = NSWindowController(window: window)
    }

    // MARK: - Dependency Injection

    private func setupDI() {
        ServiceLocator.shared.register(LocationRepository.self)         { LocationRepository() }
        ServiceLocator.shared.register(LocationManager.self)            { LocationManager() }
        ServiceLocator.shared.register(CitySearchService.self)          { CitySearchService() }
        ServiceLocator.shared.register(SettingsStorageProtocol.self)    { UserDefaultsStorage() }

        let storage = ServiceLocator.shared.resolve(SettingsStorageProtocol.self)
        self.settingsVM     = SettingsViewModel(storage: storage)
        self.locationVM     = .shared
        self.notificationVM = NotificationViewModel()

        ServiceLocator.shared.register(PrayerEngineServiceProtocol.self) { PrayerEngineService() }
    }

    // MARK: - Widget (floating NSPanel)

    private func showWidget() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 560),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.level                   = .floating
        panel.isOpaque                = false
        panel.backgroundColor         = .clear
        panel.hasShadow               = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior      = [.canJoinAllSpaces, .stationary]
        panel.contentView             = NSHostingView(rootView: WidgetView())

        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 340
            let y = screen.visibleFrame.maxY - 580
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        panel.orderFrontRegardless()
        widgetController = NSWindowController(window: panel)
    }

    private func showOnboarding() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent  = true
        window.titleVisibility             = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed        = false
        window.contentViewController = NSHostingController(
            rootView: OnboardingView {
                DispatchQueue.main.async {
                    LocationViewModel.shared.cancelFetch()
                    UserDefaults.standard.set(true, forKey: Keys.Defaults.hasCompletedOnboarding)
                    self.onboardingWindow?.animationBehavior = .none
                    self.onboardingWindow?.close()
                    // Nil AFTER main window is shown — keeps our strong reference alive
                    // through the current run loop so the window's autorelease pool
                    // entry drains before ARC releases it (prevents double-release crash)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showMainWindow()
                        self.onboardingWindow = nil
                        // self.showWidget() — Phase 5
                    }
                }
            }
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    // Show notifications even when app is in foreground.
    // If the notification carries a custom sound (stored in App Support, not bundle),
    // we suppress UNNotificationSound and play it ourselves via AVAudioPlayer.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let soundName = userInfo["soundName"] as? String ?? ""
        let customFile = userInfo["customSoundFilename"] as? String

        if soundName == "none" || soundName.isEmpty {
            completionHandler([.banner])
        } else if let filename = customFile {
            // Custom sound — play via AVAudioPlayer, suppress system sound to avoid double
            playSound(url: SoundConversionService.shared.url(for: filename), label: filename)
            completionHandler([.banner])
        } else if let sound = AppSound(rawValue: soundName), sound != .systemDefault {
            // Bundled sound — play via AVAudioPlayer, suppress system sound to avoid double
            playBundledSound(sound)
            completionHandler([.banner])
        } else {
            // System default — let macOS handle it
            completionHandler([.banner, .sound])
        }
    }

    private var notifSoundPlayer: AVAudioPlayer?

    private func playBundledSound(_ sound: AppSound) {
        guard let filename = sound.filename, let folder = sound.folder else { return }
        let url = Bundle.main.url(forResource: filename, withExtension: "aiff", subdirectory: "Sounds/\(folder)")
            ?? Bundle.main.url(forResource: filename, withExtension: "aiff")
        guard let url else {
            print("⚠️ Bundled sound not found: \(sound.rawValue)")
            return
        }
        playSound(url: url, label: sound.rawValue)
    }

    private func playSound(url: URL, label: String) {
        guard FileManager.default.fileExists(atPath: url.path),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            print("⚠️ Sound file missing: \(label)")
            return
        }
        notifSoundPlayer = player
        player.play()
    }
}
