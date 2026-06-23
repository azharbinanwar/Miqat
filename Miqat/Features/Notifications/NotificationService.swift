import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let engine = PrayerEngineService()

    // MARK: - Identifier namespaces

    private func prayerIDs(_ ref: Prayer) -> [String] {
        ["prayer.\(ref.rawValue).x",
         "prayer.\(ref.rawValue).attime",
         "prayer.\(ref.rawValue).jamaat"]
    }

    private let mulkID    = "mulk.isha"
    private let jumuahIDs = ["jumuah.x", "jumuah.missed"]

    private func kahfID(_ anchor: KahfAnchor) -> String { "kahf.\(anchor.rawValue)" }

    // MARK: - Cancel (surgical, prefix-based so date-keyed IDs are always caught)

    func cancelPrayer(_ ref: Prayer) async {
        let prefix = "prayer.\(ref.rawValue)."
        await cancelByPrefix(prefix)
    }

    func cancelMulk() async {
        await cancelByPrefix("mulk.isha.")
    }

    func cancelKahfAnchor(_ anchor: KahfAnchor) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0 == kahfID(anchor) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    func cancelJumuah() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("jumuah.") }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    private func cancelByPrefix(_ prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Schedule prayer

    func schedulePrayer(
        _ config: PrayerNotifConfig,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        await cancelPrayer(config.prayer)
        guard config.enabled else { return }

        let now   = Date()
        let today = Calendar.current.startOfDay(for: now)

        for dayOffset in 0..<3 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let entries = engine.calculateTimes(for: date, location: location, settings: settings)
            guard let entry = entries.first(where: { $0.prayer == config.prayer }),
                  let prayerDate = entry.date else { continue }

            let name = config.prayer.label
            let dk   = dateKey(for: date)
            let ref  = config.prayer.rawValue

            if let xDate = Calendar.current.date(byAdding: .minute, value: -config.xMinutes, to: prayerDate),
               xDate > now {
                await schedule(id: "prayer.\(ref).x.\(dk)",
                         title: "\(name) is approaching", body: "Get ready for \(name) prayer",
                         date: xDate, sound: config.sound, customSoundFilename: config.customSoundFilename)
            }

            if config.atPrayerTime, prayerDate > now {
                await schedule(id: "prayer.\(ref).attime.\(dk)",
                         title: "\(name) time has begun", body: "It is time to pray \(name)",
                         date: prayerDate, sound: config.sound, customSoundFilename: config.customSoundFilename)
            }

            if config.zEnabled,
               let zDate = Calendar.current.date(byAdding: .minute, value: config.zMinutes, to: prayerDate),
               zDate > now {
                await schedule(id: "prayer.\(ref).jamaat.\(dk)",
                         title: "Head to the mosque for \(name)", body: "Jamaat is starting soon",
                         date: zDate, sound: config.sound, customSoundFilename: config.customSoundFilename)
            }
        }
    }

    // MARK: - Schedule Surah Mulk

    func scheduleMulk(
        _ config: SurahMulkConfig,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        await cancelMulk()
        guard config.enabled else { return }

        let today = Calendar.current.startOfDay(for: Date())
        for dayOffset in 0..<3 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let entries = engine.calculateTimes(for: date, location: location, settings: settings)
            guard let ishaEntry = entries.first(where: { $0.prayer == .isha }),
                  let ishaDate = ishaEntry.date,
                  let mulkDate = Calendar.current.date(byAdding: .minute, value: config.minutesAfterIsha, to: ishaDate),
                  mulkDate > Date() else { continue }

            await schedule(
                id: "\(mulkID).\(dateKey(for: date))",
                title: "Surah Mulk",
                body: "Time to recite Surah Al-Mulk",
                date: mulkDate,
                sound: config.sound
            )
        }
    }

    // MARK: - Schedule Surah Kahf (weekly — Friday only)

    func scheduleKahfAnchor(
        _ anchorConfig: KahfAnchorConfig,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        await cancelKahfAnchor(anchorConfig.anchor)
        guard anchorConfig.enabled else { return }

        // Look ahead 7 days to find the right day
        let today = Calendar.current.startOfDay(for: Date())
        for dayOffset in 0..<8 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = Calendar.current.component(.weekday, from: date)

            let targetDate: Date?

            switch anchorConfig.anchor {
            case .thurMaghrib: targetDate = weekday == 5 ? anchorDate(ref: .maghrib, on: date, offset: anchorConfig.minutesAfter, location: location, settings: settings) : nil
            case .thurIsha:    targetDate = weekday == 5 ? anchorDate(ref: .isha,    on: date, offset: anchorConfig.minutesAfter, location: location, settings: settings) : nil
            case .friFajr:     targetDate = weekday == 6 ? anchorDate(ref: .fajr,    on: date, offset: anchorConfig.minutesAfter, location: location, settings: settings) : nil
            case .friDhuhr:    targetDate = weekday == 6 ? anchorDate(ref: .dhuhr,   on: date, offset: anchorConfig.minutesAfter, location: location, settings: settings) : nil
            case .friAsr:      targetDate = weekday == 6 ? anchorDate(ref: .asr,     on: date, offset: anchorConfig.minutesAfter, location: location, settings: settings) : nil
            case .customTime:
                if let fixed = anchorConfig.fixedTime {
                    // Friday at fixed time
                    if weekday == 6 {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: fixed)
                        targetDate = Calendar.current.date(bySettingHour: comps.hour ?? 8, minute: comps.minute ?? 0, second: 0, of: date)
                    } else { targetDate = nil }
                } else { targetDate = nil }
            }

            if let fireDate = targetDate, fireDate > Date() {
                await schedule(
                    id: kahfID(anchorConfig.anchor),
                    title: "Surah Kahf",
                    body: "Time to recite Surah Al-Kahf — \(anchorConfig.anchor.displayName)",
                    date: fireDate,
                    sound: anchorConfig.sound
                )
                break // Only schedule once (next occurrence)
            }
        }
    }

    // MARK: - Schedule Friday Jumu'ah

    func scheduleJumuah(
        _ config: FridayJumuahConfig,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        await cancelJumuah()
        guard config.enabled else { return }

        let today = Calendar.current.startOfDay(for: Date())
        for dayOffset in 0..<8 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekday = Calendar.current.component(.weekday, from: date)
            guard weekday == 6 else { continue }

            let entries = engine.calculateTimes(for: date, location: location, settings: settings)
            guard let dhuhrEntry = entries.first(where: { $0.prayer == .dhuhr }),
                  let dhuhrDate = dhuhrEntry.date else { continue }

            // X before khutbah
            if let xDate = Calendar.current.date(byAdding: .minute, value: -config.xMinutes, to: dhuhrDate),
               xDate > Date() {
                await schedule(
                    id: "jumuah.x",
                    title: "Jumu'ah in \(config.xMinutes) minutes",
                    body: "Friday prayer approaching — don't miss it",
                    date: xDate,
                    sound: config.sound
                )
            }

            // Z — khutbah / jamaat
            if let zDate = Calendar.current.date(byAdding: .minute, value: config.zMinutes, to: dhuhrDate),
               zDate > Date() {
                await schedule(
                    id: "jumuah.z",
                    title: "Jumu'ah khutbah starting",
                    body: "Khutbah begins now",
                    date: zDate,
                    sound: config.sound
                )
            }

            // Missed reminder
            if config.missedEnabled,
               let missedDate = Calendar.current.date(byAdding: .minute, value: config.missedMinutes, to: dhuhrDate),
               missedDate > Date() {
                await schedule(
                    id: "jumuah.missed",
                    title: "Did you pray Jumu'ah?",
                    body: "Don't forget to mark your attendance",
                    date: missedDate,
                    sound: config.sound
                )
            }

            break // Only next Friday
        }
    }

    // MARK: - Schedule all

    func scheduleAll(
        vm: NotificationViewModel,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        cancelAll()

        // XPC barrier — getPendingNotificationRequests goes through the same XPC
        // connection as removeAll. When it returns, the cancel has been fully
        // processed by the notification daemon before any add() calls fire.
        let beforeCancel = await center.pendingNotificationRequests()

        guard vm.allEnabled else {
            print("⚠️ scheduleAll skipped — master toggle OFF")
            return
        }

        // All prayer types run concurrently inside a TaskGroup.
        // Each type awaits its own add() calls sequentially — so Apple's
        // response (success or ❌ rejection) is captured per notification.
        await withTaskGroup(of: Void.self) { group in
            for config in vm.prayerConfigs {
                group.addTask { await self.schedulePrayer(config, location: location, settings: settings) }
            }
            group.addTask { await self.scheduleMulk(vm.mulkConfig, location: location, settings: settings) }
            for anchor in vm.kahfConfig.anchors {
                group.addTask { await self.scheduleKahfAnchor(anchor, location: location, settings: settings) }
            }
            group.addTask { await self.scheduleJumuah(vm.jumuahConfig, location: location, settings: settings) }
        }

        // All adds have now completed (or errored). Check what Apple actually registered.
        let after = await center.pendingNotificationRequests()
        print("✅ scheduleAll() complete — Apple confirmed \(after.count) pending")
    }

    // MARK: - Schedule If Needed (gap fill — never cancels anything)

    func scheduleIfNeeded(
        vm: NotificationViewModel,
        location: Location,
        settings: PrayerCalculationSettings
    ) async {
        guard vm.allEnabled else { return }

        let pending    = await center.pendingNotificationRequests()
        let pendingIDs = Set(pending.map(\.identifier))
        let now        = Date()
        let today      = Calendar.current.startOfDay(for: now)
        var added   = 0
        var skipped = 0

        // Prayers
        for config in vm.prayerConfigs {
            guard config.enabled else { continue }
            let ref  = config.prayer.rawValue
            let name = config.prayer.label

            for dayOffset in 0..<3 {
                guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let entries = engine.calculateTimes(for: day, location: location, settings: settings)
                guard let entry = entries.first(where: { $0.prayer == config.prayer }),
                      let pDate = entry.date else { continue }

                let dk   = dateKey(for: day)
                let xID  = "prayer.\(ref).x.\(dk)"
                if !pendingIDs.contains(xID) {
                    if let xDate = Calendar.current.date(byAdding: .minute, value: -config.xMinutes, to: pDate), xDate > now {
                        await schedule(id: xID, title: "\(name) is approaching",
                                       body: "Get ready for \(name) prayer", date: xDate, sound: config.sound)
                        added += 1
                    } else {
                        skipped += 1
                    }
                }

                if config.atPrayerTime {
                    let atID = "prayer.\(ref).attime.\(dk)"
                    if !pendingIDs.contains(atID) {
                        if pDate > now {
                            await schedule(id: atID, title: "\(name) time has begun",
                                           body: "It is time to pray \(name)", date: pDate, sound: config.sound)
                            added += 1
                        } else {
                            skipped += 1
                        }
                    }
                }

                if config.zEnabled {
                    let zID = "prayer.\(ref).jamaat.\(dk)"
                    if !pendingIDs.contains(zID) {
                        if let zDate = Calendar.current.date(byAdding: .minute, value: config.zMinutes, to: pDate), zDate > now {
                            await schedule(id: zID, title: "Head to the mosque for \(name)",
                                           body: "Jamaat is starting soon", date: zDate, sound: config.sound)
                            added += 1
                        } else {
                            skipped += 1
                        }
                    }
                }
            }
        }

        // Mulk
        if vm.mulkConfig.enabled {
            for dayOffset in 0..<3 {
                guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let id = "\(mulkID).\(dateKey(for: day))"
                guard !pendingIDs.contains(id) else { continue }
                let entries = engine.calculateTimes(for: day, location: location, settings: settings)
                if let ishaEntry = entries.first(where: { $0.prayer == .isha }),
                   let ishaDate  = ishaEntry.date,
                   let mulkDate  = Calendar.current.date(byAdding: .minute, value: vm.mulkConfig.minutesAfterIsha, to: ishaDate),
                   mulkDate > now {
                    await schedule(id: id, title: "Surah Mulk",
                                   body: "Time to recite Surah Al-Mulk", date: mulkDate, sound: vm.mulkConfig.sound)
                    added += 1
                }
            }
        }

        // Kahf — one per anchor, weekly
        for anchor in vm.kahfConfig.anchors where anchor.enabled {
            let id = kahfID(anchor.anchor)
            if !pendingIDs.contains(id) {
                await scheduleKahfAnchor(anchor, location: location, settings: settings)
                added += 1
            }
        }

        // Jumuah — if any slot missing, refill all (next Friday only)
        if vm.jumuahConfig.enabled {
            let missing = ["jumuah.x", "jumuah.z", "jumuah.missed"].filter { !pendingIDs.contains($0) }
            if !missing.isEmpty {
                await scheduleJumuah(vm.jumuahConfig, location: location, settings: settings)
                added += missing.count
            }
        }

        let after = await center.pendingNotificationRequests()
        print("✅ scheduleIfNeeded — after: \(after.count) pending | added: \(added) | past/skipped: \(skipped)")
    }

    // MARK: - Helpers

    private func dateKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func anchorDate(
        ref: Prayer,
        on date: Date,
        offset: Int,
        location: Location,
        settings: PrayerCalculationSettings
    ) -> Date? {
        let entries = engine.calculateTimes(for: date, location: location, settings: settings)
        guard let entry = entries.first(where: { $0.prayer == ref }),
              let entryDate = entry.date else { return nil }
        return Calendar.current.date(byAdding: .minute, value: offset, to: entryDate)
    }

    private func schedule(id: String, title: String, body: String, date: Date, sound: AppSound, customSoundFilename: String? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        // Always set .default so sound plays if app is not running.
        // willPresent delegate overrides with AVAudioPlayer when app IS running.
        content.sound = sound.unNotificationSound
        var userInfo: [String: String] = ["soundName": sound.rawValue]
        if let filename = customSoundFilename { userInfo["customSoundFilename"] = filename }
        content.userInfo = userInfo
        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            let ns = error as NSError
            print("❌ [\(id)] Apple rejected — \(ns.localizedDescription) (domain: \(ns.domain) code: \(ns.code))")
        }
    }
}
