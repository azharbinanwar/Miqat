import AppKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Surfaces
    private var statusItem: NSStatusItem?
    private var popoverPanel: NSPanel?
    private var popoverEventMonitor: Any?
    private var mainWindowController: NSWindowController?
    private var widgetController: NSWindowController?
    private var onboardingWindow: NSWindow?
    private var menuBarVM     : PrayerTimeViewModel!
    private var settingsVM    : SettingsViewModel!
    private var themeVM       : ThemeViewModel!
    private var locationVM    : LocationViewModel!
    private var notificationVM: NotificationViewModel!
    private var hijriVM       : HijriCalendarViewModel!
    private var trackerVM     : PrayerTrackerViewModel!
    private var statusTimer   : Timer?
    private var wakeObserver  : Any?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        setupDI()
        setupPrayerTimes()
        setupStatusItem()
        setupPopover()

        NotificationCenter.default.addObserver(forName: .settingsDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            hijriVM.update(offset: settingsVM.settings.hijriAdjustment)
            let mode = settingsVM.settings.floatingPanelMode
            if mode == .off {
                widgetController?.close()
                widgetController = nil
            } else if let panel = widgetController?.window as? NSPanel {
                // Apply level + behavior so mode changes (Normal ↔ Always) take effect immediately
                switch mode {
                case .off: break
                case .normal:
                    panel.level              = .normal
                    panel.collectionBehavior = [.managed]
                case .always:
                    panel.level              = .floating
                    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
                }
                let newSize = settingsVM.settings.floatingPanelSize.panelSize
                var frame = panel.frame
                frame.origin.y = frame.maxY - newSize.height
                frame.size = newSize
                panel.setFrame(frame, display: true, animate: true)
            } else {
                showWidget()
            }
        }

        if UserDefaults.standard.bool(forKey: Keys.Defaults.hasCompletedOnboarding) {
            if settingsVM.settings.openWindowOnLaunch { showMainWindow() }
            showWidget()
        } else {
            showOnboarding()
        }
    }

    // MARK: - Prayer Times (shared for Menu Bar)

    private func setupPrayerTimes() {
        let repo = ServiceLocator.shared.resolve(LocationRepository.self)
        repo.seedIfEmpty()

        menuBarVM = PrayerTimeViewModel()
        menuBarVM.onEntriesLoaded = { [weak self] _ in
            self?.trackerVM.seedGaps()
        }
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
            // Re-load prayer times → triggers onEntriesLoaded → fillGaps
            if let loc = ServiceLocator.shared.resolve(LocationRepository.self).getActiveLocation() {
                self.menuBarVM.load(location: loc)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if let loc = ServiceLocator.shared.resolve(LocationRepository.self).getActiveLocation() {
                self.menuBarVM.load(location: loc)
            }
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
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        var popoverView = PopoverView(prayerVM: menuBarVM, settingsVM: settingsVM)
        popoverView.onOpenApp = { [weak self] in
            self?.closePopover()
            self?.showMainWindow()
        }
        popoverView.onOpenSettings = { [weak self] in
            self?.closePopover()
            self?.showMainWindow(tab: .settings)
        }
        panel.contentView = NSHostingView(rootView: popoverView.environment(hijriVM).environment(themeVM).environment(trackerVM).environment(menuBarVM))
        popoverPanel = panel
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let panel = popoverPanel else { return }

        if panel.isVisible {
            closePopover()
        } else {
            if let buttonWindow = button.window,
               let screen = buttonWindow.screen {
                let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
                let x = buttonRect.midX - panel.frame.width / 2
                let y = buttonRect.minY - panel.frame.height - 4
                // Keep panel within screen bounds
                let clampedX = min(max(x, screen.visibleFrame.minX), screen.visibleFrame.maxX - panel.frame.width)
                panel.setFrameOrigin(NSPoint(x: clampedX, y: y))
            }
            panel.contentView?.wantsLayer = true
            panel.alphaValue = 0
            panel.orderFront(nil)

            DispatchQueue.main.async {
                // Fade in
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 0.2
                panel.animator().alphaValue = 1
                NSAnimationContext.endGrouping()

                // Spring slide-down from menu bar
                if let layer = panel.contentView?.layer {
                    let spring = CASpringAnimation(keyPath: "position.y")
                    spring.fromValue = layer.position.y + 20
                    spring.toValue   = layer.position.y
                    spring.stiffness = 280
                    spring.damping   = 22
                    spring.mass      = 1.0
                    spring.initialVelocity = 0
                    spring.duration  = spring.settlingDuration
                    layer.add(spring, forKey: "springIn")
                }
            }
            popoverEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        guard let panel = popoverPanel else { return }
        panel.orderOut(nil)
        if let monitor = popoverEventMonitor {
            NSEvent.removeMonitor(monitor)
            popoverEventMonitor = nil
        }
    }

    // MARK: - Main Window

    func showMainWindow(tab: SidebarItem = .today) {
        if let existing = mainWindowController {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .miqatSwitchTab, object: tab)
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
        window.contentView = NSHostingView(rootView: MainWindowView(initialTab: tab)
            .environment(settingsVM)
            .environment(themeVM)
            .environment(trackerVM)
            .environment(menuBarVM)
            .environment(locationVM)
            .environment(notificationVM)
            .environment(hijriVM))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindowController = NSWindowController(window: window)
        NSApp.setActivationPolicy(.regular)
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.mainWindowController = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Dependency Injection

    private func setupDI() {
        ServiceLocator.shared.register(LocationRepository.self)         { LocationRepository() }
        ServiceLocator.shared.register(LocationManager.self)            { LocationManager() }
        ServiceLocator.shared.register(CitySearchService.self)          { CitySearchService() }
        ServiceLocator.shared.register(SettingsStorageProtocol.self)    { UserDefaultsStorage() }

        let storage = ServiceLocator.shared.resolve(SettingsStorageProtocol.self)
        self.settingsVM     = SettingsViewModel(storage: storage)
        self.themeVM        = ThemeViewModel()
        self.trackerVM      = PrayerTrackerViewModel()

        self.locationVM     = .shared
        self.notificationVM = NotificationViewModel()
        self.hijriVM        = HijriCalendarViewModel(offset: storage.load()?.hijriAdjustment ?? 0)

        ServiceLocator.shared.register(PrayerEngineServiceProtocol.self) { PrayerEngineService() }
    }

    // MARK: - Widget (floating NSPanel)

    private func showWidget() {
        widgetController?.close()
        widgetController = nil

        guard settingsVM.settings.floatingPanelMode != .off else { return }

        let size = settingsVM.settings.floatingPanelSize.panelSize
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        switch settingsVM.settings.floatingPanelMode {
        case .off: break
        case .normal:
            panel.level              = .normal
            panel.collectionBehavior = [.managed]
        case .always:
            panel.level              = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        }
        panel.isOpaque                = false
        panel.backgroundColor         = .clear
        panel.hasShadow               = true
        panel.isMovableByWindowBackground = true
        panel.contentView             = NSHostingView(rootView: FloatingPanelView(prayerVM: menuBarVM, onOpenSettings: { [weak self] in
            self?.showMainWindow(tab: .settings)
        }).environment(settingsVM).environment(themeVM).environment(trackerVM).environment(hijriVM).environment(menuBarVM))

        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.Defaults.floatingPanelX) != nil {
            let origin = NSPoint(
                x: defaults.double(forKey: Keys.Defaults.floatingPanelX),
                y: defaults.double(forKey: Keys.Defaults.floatingPanelY)
            )
            panel.setFrameOrigin(origin)
        } else if let screen = NSScreen.main {
            panel.setFrameOrigin(NSPoint(
                x: screen.visibleFrame.maxX - 340,
                y: screen.visibleFrame.maxY - 580
            ))
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak panel] _ in
            guard let origin = panel?.frame.origin else { return }
            UserDefaults.standard.set(origin.x, forKey: Keys.Defaults.floatingPanelX)
            UserDefaults.standard.set(origin.y, forKey: Keys.Defaults.floatingPanelY)
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
                    if let raw = UserDefaults.standard.string(forKey: Keys.Defaults.selectedMadhab),
                       let madhab = Madhab(rawValue: raw) {
                        self.settingsVM.update { $0.madhab = madhab }
                    }
                    self.onboardingWindow?.animationBehavior = .none
                    self.onboardingWindow?.close()
                    // Nil AFTER main window is shown — keeps our strong reference alive
                    // through the current run loop so the window's autorelease pool
                    // entry drains before ARC releases it (prevents double-release crash)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self.settingsVM.settings.openWindowOnLaunch {
                            self.showMainWindow()
                        }
                        self.onboardingWindow = nil
                        self.showWidget()
                    }
                }
            }
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        onboardingWindow = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { showMainWindow() }
        return true
    }

    // Show notifications even when app is in foreground.
    // CUSTOM SOUND DISABLED: willPresent only fires when app is foreground (menu bar background = never fires).
    // AVAudioPlayer workaround therefore unreliable. Revisit when Apple fixes UNNotificationSound on macOS (FB11642483).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
