# Miqat — macOS Prayer Times App

## What We Are Building
A full native macOS prayer times app with THREE surfaces running together:

1. **Menu Bar** — always visible, shows next prayer + live countdown
2. **Desktop Widget** — beautiful floating card on desktop, always on screen, resizable
3. **Full App Window** — click Dock icon or menu bar to open full app with all prayer info

Focus: prayer times only. No Quran reading, no extra Islamic content. Just prayer info done perfectly.

## Current State (as of Phase 0)
- App runs: MenuBarExtra shows in menu bar
- AppDelegate launches floating NSPanel (WidgetView placeholder — needs full UI)
- Core files done: AsyncState, ServiceLocator, UseCase
- Folder structure in place

## Tech Stack
- Swift 5.9+, SwiftUI + AppKit, macOS 13+, Universal binary
- **Adhan-Swift** — prayer calculation (batoulapps/adhan-swift) — NOT YET ADDED
- **LaunchAtLogin** — login item — NOT YET ADDED
- CoreLocation, UserNotifications, AVFoundation, CoreData/SwiftData
- No backend. Fully local. Offline.

## 3 Surfaces
### 1. Menu Bar (always visible)
- Format: `🕌 Asr  42:18`
- Red + ⚠ when < 20 min
- Green ✓ briefly when prayer marked
- Click → opens popover with all times

### 2. Desktop Widget (floating NSPanel)
- Always on screen, launches at login
- Resizable (compact / standard / large)
- Draggable anywhere on desktop
- Beautiful gradient background changes by time of day
- Shows: all 6 prayers, big countdown, current prayer highlighted, status icons ✓✗○
- Bottom: Madhab toggle, streak, settings

### 3. Full App Window
- Opens from Dock or menu bar
- Full prayer info: today's times, tracker, settings, stats
- Same design language as widget but larger

## Widget Time-of-Day Gradients
- Fajr: deep navy → warm purple
- Sunrise: orange → pink → gold
- Dhuhr: bright teal → sky blue
- Asr: amber → warm orange
- Maghrib: deep orange → purple → pink
- Isha: deep navy → dark purple

## Colour Palette
| Name | Hex | Use |
|------|-----|-----|
| Deep Teal | #0D9488 | Primary, current prayer |
| Royal Purple | #7C3AED | Night widget bg |
| Warm Gold | #D97706 | Fajr/sunrise/streaks |
| Alert Red | #DC2626 | < 20 min warning |

## Build Order (follow strictly, one at a time)
1. ✅ Phase 0 — App structure, Core files, NSPanel widget placeholder running
2. ⏳ Phase 1 — Add Adhan-Swift, build PrayerEngine (real prayer times)
3. Phase 2 — Full WidgetView UI (all prayers, gradient, countdown, rows)
4. Phase 3 — Menu Bar upgrade (NSStatusItem, live countdown)
5. Phase 4 — Popover Panel (click menu bar)
6. Phase 5 — Full App Window
7. Phase 6 — Notifications (20min early, on-time, end, I Prayed, snooze)
8. Phase 7 — Prayer Tracker (CoreData, streaks, stats)
9. Phase 8 — Settings Panel
10. Phase 9 — Onboarding (3 screens)
11. Phase 10 — Azan Audio
12. Phase 11 — Polish + App Store

## Project Folder Structure
```
Miqat/
  App/              — AppDelegate, entry point
  Features/
    Widget/         — floating NSPanel SwiftUI view
    Popover/        — NSPopover content
    MainWindow/     — full app window
    PrayerEngine/   — Adhan-Swift wrapper, location, Madhab
    Notifications/  — UNUserNotificationCenter
    Tracker/        — CoreData prayer history
    Settings/       — preferences
    Audio/          — azan AVFoundation
  Core/
    AsyncState.swift
    ServiceLocator.swift
    UseCase.swift
```

## Architecture: SwiftUI Clean Architecture
See ARCHITECTURE_GUIDE.md — same layers as Flutter BLoC but in Swift:
Entity → Model → Repository → UseCase → ViewModel (@Observable) → View

## What NOT to Build
- Qibla compass (future)
- Quran reading
- Islamic content beyond prayer times
- Any backend or user accounts
