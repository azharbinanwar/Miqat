import Foundation
import UserNotifications

struct NotificationGap {
    let identifier: String
    let type: GapType

    enum GapType {
        case prayerX(ReferenceTime)
        case prayerAtTime(ReferenceTime)
        case prayerJamaat(ReferenceTime)
        case mulk
        case kahf(KahfAnchor)
        case jumuahX
        case jumuahZ
        case jumuahMissed
    }
}

final class NotificationCounter {

    // MARK: - Expected counts per type (based on config)

    static func expectedPrayerCount(_ config: PrayerNotifConfig) -> Int {
        guard config.enabled else { return 0 }
        var count = 3
        if config.atPrayerTime { count += 3 }
        if config.zEnabled     { count += 3 }
        return count
    }

    static func expectedMulkCount(_ config: SurahMulkConfig) -> Int {
        config.enabled ? 3 : 0
    }

    static func expectedKahfCount(_ config: SurahKahfConfig) -> Int {
        config.anchors.filter { $0.enabled }.count
    }

    static func expectedJumuahCount(_ config: FridayJumuahConfig) -> Int {
        guard config.enabled else { return 0 }
        var count = 2
        if config.missedEnabled { count += 1 }
        return count
    }

    // MARK: - Find gaps (what's missing from pending)

    static func findGaps(
        vm: NotificationViewModel,
        pending: [UNNotificationRequest]
    ) -> [NotificationGap] {
        let pendingIDs = Set(pending.map { $0.identifier })
        var gaps: [NotificationGap] = []
        let today = Calendar.current.startOfDay(for: Date())

        for config in vm.prayerConfigs {
            guard config.enabled else { continue }
            let ref = config.referenceTime

            for dayOffset in 0..<3 {
                guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let dk = dateKey(day)

                let xID = "prayer.\(ref.rawValue).x.\(dk)"
                if !pendingIDs.contains(xID) {
                    gaps.append(NotificationGap(identifier: xID, type: .prayerX(ref)))
                }

                if config.atPrayerTime {
                    let atID = "prayer.\(ref.rawValue).attime.\(dk)"
                    if !pendingIDs.contains(atID) {
                        gaps.append(NotificationGap(identifier: atID, type: .prayerAtTime(ref)))
                    }
                }

                if config.zEnabled {
                    let zID = "prayer.\(ref.rawValue).jamaat.\(dk)"
                    if !pendingIDs.contains(zID) {
                        gaps.append(NotificationGap(identifier: zID, type: .prayerJamaat(ref)))
                    }
                }
            }
        }

        if vm.mulkConfig.enabled {
            for dayOffset in 0..<3 {
                guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: today) else { continue }
                let id = "mulk.isha.\(dateKey(day))"
                if !pendingIDs.contains(id) {
                    gaps.append(NotificationGap(identifier: id, type: .mulk))
                }
            }
        }

        for anchor in vm.kahfConfig.anchors where anchor.enabled {
            let id = "kahf.\(anchor.anchor.rawValue)"
            if !pendingIDs.contains(id) {
                gaps.append(NotificationGap(identifier: id, type: .kahf(anchor.anchor)))
            }
        }

        if vm.jumuahConfig.enabled {
            if !pendingIDs.contains("jumuah.x") {
                gaps.append(NotificationGap(identifier: "jumuah.x", type: .jumuahX))
            }
            if !pendingIDs.contains("jumuah.z") {
                gaps.append(NotificationGap(identifier: "jumuah.z", type: .jumuahZ))
            }
            if vm.jumuahConfig.missedEnabled, !pendingIDs.contains("jumuah.missed") {
                gaps.append(NotificationGap(identifier: "jumuah.missed", type: .jumuahMissed))
            }
        }

        return gaps
    }

    // MARK: - Summary (for debug / logging)

    static func summary(vm: NotificationViewModel, pending: [UNNotificationRequest]) -> String {
        let pendingIDs = Set(pending.map { $0.identifier })
        var lines: [String] = ["--- Notification Count Summary ---"]
        let today = Calendar.current.startOfDay(for: Date())
        let days  = (0..<3).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }

        for config in vm.prayerConfigs {
            guard config.enabled else {
                lines.append("\(config.referenceTime.rawValue): disabled")
                continue
            }
            let ref = config.referenceTime
            let xCount      = days.filter { pendingIDs.contains("prayer.\(ref.rawValue).x.\(dateKey($0))") }.count
            let atCount     = config.atPrayerTime ? days.filter { pendingIDs.contains("prayer.\(ref.rawValue).attime.\(dateKey($0))") }.count : -1
            let jamaatCount = config.zEnabled     ? days.filter { pendingIDs.contains("prayer.\(ref.rawValue).jamaat.\(dateKey($0))") }.count : -1

            var parts = ["X: \(xCount)/3"]
            if atCount >= 0     { parts.append("at: \(atCount)/3") }
            if jamaatCount >= 0 { parts.append("jamaat: \(jamaatCount)/3") }
            lines.append("\(ref.rawValue): \(parts.joined(separator: " · "))")
        }

        let mulkCount = vm.mulkConfig.enabled
            ? days.filter { pendingIDs.contains("mulk.isha.\(dateKey($0))") }.count
            : -1
        lines.append(vm.mulkConfig.enabled ? "Mulk: \(mulkCount)/3" : "Mulk: disabled")

        let kahfEnabled = vm.kahfConfig.anchors.filter { $0.enabled }
        let kahfCount   = kahfEnabled.filter { pendingIDs.contains("kahf.\($0.anchor.rawValue)") }.count
        lines.append("Kahf: \(kahfCount)/\(kahfEnabled.count)")

        if vm.jumuahConfig.enabled {
            let xOk    = pendingIDs.contains("jumuah.x")      ? "✓" : "✗"
            let zOk    = pendingIDs.contains("jumuah.z")      ? "✓" : "✗"
            let missOk = vm.jumuahConfig.missedEnabled ? (pendingIDs.contains("jumuah.missed") ? "✓" : "✗") : "—"
            lines.append("Jumu'ah: X\(xOk) Z\(zOk) missed\(missOk)")
        } else {
            lines.append("Jumu'ah: disabled")
        }

        lines.append("Total pending: \(pending.count)")
        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private static func dateKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
