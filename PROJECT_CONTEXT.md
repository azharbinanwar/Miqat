# Miqat — Project Context

Read this at the start of every new thread alongside ARCHITECTURE_GUIDE.md.

---

## Phase Status

| Phase | Feature | Status |
|-------|---------|--------|
| 0 | App structure, Core files, NSPanel placeholder | ✅ Done |
| 1 | Prayer engine (Adhan-Swift), Location, PrayerEngineService | ✅ Done |
| 2 | WidgetView full UI (gradient, countdown, prayer rows) | ✅ Done |
| 3 | Menu bar live countdown (NSStatusItem, timer) | ✅ Done |
| 4 | Popover (now NSPanel, not NSPopover) | ✅ Done |
| 5 | Full app window (MainWindowView, Sidebar, all tabs) | ✅ Done |
| 6 | Notifications (scheduling, configs, UI) | ✅ Done — sound parked |
| 7 | Prayer Tracker (CoreData, mark prayed, streaks, stats) | ⏳ Next |
| 8 | Settings panel (exists, may be incomplete) | ⏳ |
| 9 | Onboarding (partially exists) | ⏳ |
| 10 | Azan Audio | ⏳ Parked (Apple bug) |
| 11 | Polish + App Store | ⏳ |

---

## Remaining Open Items

### Small (Phase 6 completion)
- "I Prayed" action button on notification banner via `UNNotificationAction`

### Phase 7 — Prayer Tracker
- CoreData/SwiftData schema for prayer history
- Mark prayed / missed per prayer per day
- Streak calculation
- Stats view (Tracker + Stats tabs exist in sidebar, need implementation)

### Phase 8 — Settings
- Review SettingsView for completeness against CLAUDE.md spec

### Phase 9 — Onboarding
- 3-screen flow: location permission → notification permission → madhab selection

### Phase 10 — Azan Audio (PARKED)
- Blocked by Apple bug FB11642483: `UNNotificationSound(named:)` unreliable on macOS
- `willPresent` only fires when app is foreground — menu bar background = never fires
- Revisit when Apple fixes or a reliable workaround is found

---

## Key Decisions Log

| Decision | Why |
|----------|-----|
| NSPanel instead of NSPopover | NSPopover can't appear above full-screen apps |
| Sound picker UI commented out | Apple bug FB11642483 — UNNotificationSound unreliable on macOS |
| Date-based notification IDs (`prayer.fajr.x.20260621`) | Prevents collision when scheduleIfNeeded runs on different day than scheduleAll |
| Prefix-based cancel (not ID-based) | Computed specific IDs miss slots scheduled from a different date |
| Sequential `await center.add()` | Avoids XPC race condition — do NOT use TaskGroup |
| Mac wake observer stored as `wakeObserver: Any?` | ARC deallocates unstored block-based observer, observer never fires |
| `scheduleIfNeeded()` never cancels | Gap fill only — avoids disrupting already-pending valid notifications |
| Friday Jumu'ah label hardcoded as "Friday Jumu'ah" | Not derived from `ReferenceTime.dhuhr` which returns "Dhuhr" |
| Sound files are `.aiff` | AVAudioPlayer requires uncompressed audio; converted from .mp3 |
| Y-nudge (snooze) notifications NOT pre-scheduled | Scheduled on-demand via banner action only |

---

## Known Bugs / Apple Quirks

- **FB11642483** — `UNNotificationSound(named:)` unreliable on macOS even with `.aiff` at bundle root. Use `.default` until Apple fixes.
- **`willPresent` foreground-only** — `UNUserNotificationCenterDelegate.willPresent` does NOT fire when app is a menu bar app running in background. Cannot use for custom sound playback.
- **Block-based `NSWorkspace` observer** — `addObserver(forName:using:)` returns a token that must be stored. If not stored, ARC deallocates it and the observer silently stops working.
- **NSPopover + full-screen** — NSPopover window level is always 0, cannot be raised above full-screen apps. NSPanel with `.popUpMenu` level + `.fullScreenAuxiliary` is the fix.

---

## Notification Sound Current State

All notifications: `content.sound = .default` (system ping).
Custom sound picker commented out in `NotificationsView` with this comment:
```
// SOUND PICKER DISABLED: UNNotificationSound custom sound unreliable on macOS (Apple bug FB11642483). Re-enable when fixed.
```
`willPresent` simplified to: `completionHandler([.banner, .sound])` — no custom playback.

---

## Important File Locations

| What | Where |
|------|-------|
| All Notification.Name extensions | `Features/MainWindow/ViewModels/SettingsViewModel.swift` |
| SidebarItem enum | `Features/MainWindow/Components/SidebarView.swift` |
| Surah/Jumuah configs | `Core/SurahNotifConfig.swift` |
| Prayer configs per prayer | `Features/Notifications/NotificationsView.swift` (PrayerNotifConfig) |
| Sound files (.aiff) | `Features/Audio/Sounds/Adhan/` and `Sounds/Notification/` |
| AppDelegate (owns all VMs) | `App/AppDelegate.swift` |
| Mac wake observer | `App/AppDelegate.swift` — `private var wakeObserver: Any?` |
| Popover dismiss monitor | `App/AppDelegate.swift` — `private var popoverEventMonitor: Any?` |
