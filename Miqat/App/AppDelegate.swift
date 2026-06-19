import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Surfaces
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindowController: NSWindowController?
    private var widgetController: NSWindowController?
    private var onboardingWindow: NSWindow?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupDI()
        setupStatusItem()
        setupPopover()

        // DEBUG: always show onboarding — remove before release
        showOnboarding()
//         RELEASE: uncomment below and remove line above
//         if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
//             showMainWindow(); showWidget()
//         } else { showOnboarding() }
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
        // Format: icon + prayer name + countdown
        // e.g.  "  Asr  42:18"
        // Warning colours applied via attributed string
        let countdown = MockPrayerData.countdown
        let mins = minutesRemaining(from: countdown)

        let iconAttachment = NSTextAttachment()
        if let img = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: nil) {
            iconAttachment.image = img
        }

        let fullText = "  \(MockPrayerData.nextPrayer)  \(countdown)"
        let attrStr  = NSMutableAttributedString(string: fullText)

        let warningColor: NSColor = mins <= 20 ? NSColor(Color(hex: "#DC2626")) :
                                    mins <= 30 ? NSColor(Color(hex: "#F59E0B")) :
                                    .labelColor

        attrStr.addAttribute(.foregroundColor, value: warningColor,
                             range: NSRange(fullText.startIndex..., in: fullText))
        attrStr.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
                             range: NSRange(fullText.startIndex..., in: fullText))

        button.attributedTitle = attrStr
    }

    private func minutesRemaining(from countdown: String) -> Int {
        let parts = countdown.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return 999 }
        return parts[0] * 60 + parts[1]
    }

    // MARK: - Popover

    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        pop.contentSize           = NSSize(width: 320, height: 480)
        pop.contentViewController = NSHostingController(rootView: PopoverView())
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
        print("[AppDelegate] creating NSHostingView for MainWindowView")
        window.contentView = NSHostingView(rootView: MainWindowView())
        print("[AppDelegate] NSHostingView created — making key")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        print("[AppDelegate] main window shown")
        mainWindowController = NSWindowController(window: window)
    }

    // MARK: - Dependency Injection

    private func setupDI() {
        ServiceLocator.shared.register(LocationRepository.self)  { LocationRepository() }
        ServiceLocator.shared.register(LocationManager.self)     { LocationManager() }
        ServiceLocator.shared.register(CitySearchService.self)   { CitySearchService() }
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
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
}
