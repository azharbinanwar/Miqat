import Foundation
import Observation

/// Returned by both getCurrentStreak and getMaxStreak — same shape for easy display
struct StreakResult {
    let days: Int
    let from: Date
    let to  : Date

    static let empty = StreakResult(days: 0, from: Date(), to: Date())
}

@Observable
final class PrayerTrackerViewModel {
    private(set) var todayRecords: [PrayerRecord] = []
    private(set) var currentStreak: Int = 0
    private(set) var todayCount: Int = 0   // prayed on time today

    private let repo: PrayerTrackerRepository

    private static let maxBackfillDays = 90

    init(repo: PrayerTrackerRepository = (try? LocalPrayerTrackerRepository()) ?? NullPrayerTrackerRepository()) {
        self.repo = repo
        reload()
    }

    // Single entry point — call whenever prayer times are (re)calculated.
    // Seeds everything between last recorded prayer and currently active prayer as missed.
    // Never touches the active prayer or anything after it.
    func seedGaps() {
        let now = Date()
        let cal = Calendar.current
        let cap = cal.date(byAdding: .day, value: -Self.maxBackfillDays, to: cal.startOfDay(for: now))!
        let allRecords = (try? repo.records(from: cap, to: now.addingTimeInterval(1))) ?? []

        let lastRecordedTime = allRecords.map(\.prayerTime).max()
        let fromDate: Date

        guard let location = ServiceLocator.shared.resolve(LocationRepository.self).getActiveLocation() else { return }
        let settings = ServiceLocator.shared.resolve(SettingsStorageProtocol.self).load()?.prayerCalculationSettings ?? .default
        let engine   = ServiceLocator.shared.resolve(PrayerEngineServiceProtocol.self)

        if let lrt = lastRecordedTime {
            fromDate = lrt
        } else {
            // New user: use today's actual Fajr to decide anchor
            // Before Fajr (overnight) → yesterday midnight so Isha from prev day is captured
            // After Fajr → today midnight so we don't over-seed previous days
            let todayFajr = engine.prayers(from: cal.startOfDay(for: now), to: cal.startOfDay(for: now), location: location, settings: settings)
                .first(where: { $0.0 == .fajr })?.1 ?? cal.startOfDay(for: now)
            fromDate = now < todayFajr
                ? cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now))!
                : cal.startOfDay(for: now)
        }

        let fmt = DateFormatter(); fmt.dateFormat = "MMM d HH:mm"

        let allEntries = engine.prayers(from: fromDate, to: now, location: location, settings: settings)
            .filter { lastRecordedTime == nil || $0.1 > lastRecordedTime! }

        guard let activeIdx = allEntries.lastIndex(where: { $0.1 <= now }) else {
            print("[seedGaps] nothing to seed — no active entry ≤ now (\(fmt.string(from: now)))")
            return
        }
        let active = allEntries[activeIdx]
        print("[seedGaps] active=\(active.0) @ \(fmt.string(from: active.1)), seeding \(activeIdx) entries")
        let toSeed = allEntries.prefix(upTo: activeIdx)

        let existing = Set(allRecords.map { "\($0.prayer)_\(cal.startOfDay(for: $0.prayerTime).timeIntervalSince1970)" })

        for (prayer, pTime) in toSeed where prayer.isPrayer {
            let key = "\(prayer)_\(cal.startOfDay(for: pTime).timeIntervalSince1970)"
            guard !existing.contains(key) else { continue }
            try? repo.save(PrayerRecord(prayer: prayer, prayerTime: pTime, status: .missed))
        }

        reload()
    }

    // Records for any given date — used to match displayEntries date
    func records(for date: Date) -> [PrayerRecord] {
        (try? repo.records(for: date)) ?? []
    }

    // One DB hit for a week — keyed by startOfDay
    func weekRecords(from start: Date) -> [Date: [PrayerRecord]] {
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        let all = (try? repo.records(from: start, to: end)) ?? []
        return Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.prayerTime) }
    }

    // One DB hit for any date range — keyed by startOfDay
    func rangeRecords(from start: Date, to end: Date) -> [Date: [PrayerRecord]] {
        let all = (try? repo.records(from: start, to: end)) ?? []
        return Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.prayerTime) }
    }

    // One DB hit for a month — keyed by startOfDay
    func monthRecords(for month: Date) -> [Date: [PrayerRecord]] {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: month)),
              let end   = cal.date(byAdding: .month, value: 1, to: start) else { return [:] }
        let all = (try? repo.records(from: start, to: end)) ?? []
        return Dictionary(grouping: all) { cal.startOfDay(for: $0.prayerTime) }
    }

    // Load from DB once (launch or day change), then memory is source of truth
    func reload() {
        todayRecords  = (try? repo.records(for: Date())) ?? []
        recomputeStats()
    }


    // Create a new record (no existing record for this prayer/date)
    func create(prayer: Prayer, prayerTime: Date, status: PrayerTrackerStatus) {
        let record = PrayerRecord(prayer: prayer, prayerTime: prayerTime, status: status, markedAt: Date())
        try? repo.save(record)
        if Calendar.current.isDateInToday(prayerTime) {
            todayRecords.append(record)
        }
        recomputeStats()
    }

    // Unified mark — today: memory + DB, past: DB only
    func mark(_ record: PrayerRecord, as status: PrayerTrackerStatus) {
        var updated       = record
        updated.status    = status
        updated.markedAt  = Date()
        try? repo.update(updated)
        if Calendar.current.isDateInToday(record.prayerTime),
           let idx = todayRecords.firstIndex(where: { $0.id == record.id }) {
            todayRecords[idx] = updated
        }
        recomputeStats()
    }

    // DEBUG — seed 10 days of mixed test data, call once from AppDelegate #if DEBUG
    func seedDebugData() {
        let cal = Calendar.current
        let statuses: [PrayerTrackerStatus] = [.prayedOnTime, .prayedWithJamaat, .prayedKaza, .prayedOnTime, .missed]
        for dayOffset in (-9)...(-1) {
            let day  = cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: Date()))!
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let existing = (try? repo.records(from: day, to: next)) ?? []
            guard existing.isEmpty else { continue }
            for (i, prayer) in Prayer.allCases.filter(\.isPrayer).enumerated() {
                let status = statuses[i % statuses.count]
                let record = PrayerRecord(prayer: prayer, prayerTime: day, status: status, markedAt: day)
                try? repo.save(record)
            }
        }
        reload()
    }

#if DEBUG
    @discardableResult
    func debugInsert(from: Date, to: Date, prayers: [Prayer], status: DebugSeedStatus) -> Int {
        let cal  = Calendar.current
        let now  = Date()
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: from), to: cal.startOfDay(for: to)).day ?? 0
        var count = 0
        for offset in 0...max(0, days) {
            let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: from))!
            guard day <= now else { continue }
            for (i, prayer) in prayers.enumerated() {
                let st = status.resolve(index: i, dayOffset: offset)
                let record = PrayerRecord(prayer: prayer, prayerTime: day, status: st, markedAt: day)
                try? repo.save(record)
                count += 1
            }
        }
        reload()
        return count
    }

    @discardableResult
    func debugDelete(from: Date, to: Date) -> Int {
        let cal  = Calendar.current
        let end  = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: to))!
        let recs = (try? repo.records(from: cal.startOfDay(for: from), to: end)) ?? []
        recs.forEach { try? repo.delete(id: $0.id) }
        reload()
        return recs.count
    }

    func debugDeleteAll() {
        try? repo.deleteAll()
        reload()
    }
#endif

    private func recomputeStats() {
        todayCount    = todayRecords.filter { $0.status.keepsStreak }.count
        currentStreak = (try? repo.getCurrentStreak())?.days ?? 0
    }

    func getCurrentStreak() -> StreakResult { (try? repo.getCurrentStreak()) ?? .empty }
    func getMaxStreak()     -> StreakResult { (try? repo.getMaxStreak())     ?? .empty }
}

// Fallback so init never crashes when SwiftData container fails
private final class NullPrayerTrackerRepository: PrayerTrackerRepository {
    func save(_ record: PrayerRecord) throws {}
    func update(_ record: PrayerRecord) throws {}
    func records(for date: Date) throws -> [PrayerRecord] { [] }
    func records(from: Date, to: Date) throws -> [PrayerRecord] { [] }
    func delete(id: UUID) throws {}
    func deleteAll() throws {}
    func getCurrentStreak() throws -> StreakResult { .empty }
    func getMaxStreak()     throws -> StreakResult { .empty }
}
