import Foundation
import SwiftData

// SwiftData persistent model — mirrors PrayerRecord 1:1
@Model
final class PrayerRecordModel {
    @Attribute(.unique) var id: UUID
    var prayerRaw:    String
    var prayerTime:   Date
    var statusRaw:    String
    var markedAt:     Date?

    init(from record: PrayerRecord) {
        self.id         = record.id
        self.prayerRaw  = record.prayer.rawValue
        self.prayerTime = record.prayerTime
        self.statusRaw  = record.status.rawValue
        self.markedAt   = record.markedAt
    }

    func toDomain() -> PrayerRecord? {
        guard let prayer = Prayer(rawValue: prayerRaw),
              let status = PrayerTrackerStatus(rawValue: statusRaw) else { return nil }
        return PrayerRecord(id: id, prayer: prayer, prayerTime: prayerTime, status: status, markedAt: markedAt)
    }
}

final class LocalPrayerTrackerRepository: PrayerTrackerRepository {
    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(for: PrayerRecordModel.self)
    }

    @MainActor
    func save(_ record: PrayerRecord) throws {
        let model = PrayerRecordModel(from: record)
        container.mainContext.insert(model)
        try container.mainContext.save()
    }

    @MainActor
    func update(_ record: PrayerRecord) throws {
        let id = record.id
        let descriptor = FetchDescriptor<PrayerRecordModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let existing = try container.mainContext.fetch(descriptor).first else { return }
        existing.statusRaw = record.status.rawValue
        existing.markedAt  = record.markedAt
        try container.mainContext.save()
    }

    @MainActor
    func records(for date: Date) throws -> [PrayerRecord] {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return try records(from: start, to: end)
    }

    @MainActor
    func records(from: Date, to: Date) throws -> [PrayerRecord] {
        let descriptor = FetchDescriptor<PrayerRecordModel>(
            predicate: #Predicate { $0.prayerTime >= from && $0.prayerTime < to },
            sortBy: [SortDescriptor(\.prayerTime)]
        )
        return try container.mainContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    @MainActor
    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<PrayerRecordModel>(
            predicate: #Predicate { $0.id == id }
        )
        if let model = try container.mainContext.fetch(descriptor).first {
            container.mainContext.delete(model)
            try container.mainContext.save()
        }
    }

    @MainActor
    func deleteAll() throws {
        try container.mainContext.delete(model: PrayerRecordModel.self)
        try container.mainContext.save()
    }

    @MainActor
    func getCurrentStreak() throws -> StreakResult {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let cap   = cal.date(byAdding: .day, value: -90, to: today)!

        let descriptor = FetchDescriptor<PrayerRecordModel>(
            predicate: #Predicate { $0.prayerTime >= cap },
            sortBy: [SortDescriptor(\.prayerTime, order: .reverse)]
        )
        let all   = try container.mainContext.fetch(descriptor)
        let byDay = Dictionary(grouping: all) { cal.startOfDay(for: $0.prayerTime) }

        // Check today first — any missed prayer today breaks the streak immediately
        let todayRecords = byDay[today] ?? []
        let todayHasMiss = todayRecords.contains { PrayerTrackerStatus(rawValue: $0.statusRaw) == .missed }
        if todayHasMiss {
            return StreakResult(days: 0, from: today, to: today)
        }
        let todayPrayed = todayRecords.filter { r in
            guard let p = Prayer(rawValue: r.prayerRaw) else { return false }
            return p.isPrayer && (PrayerTrackerStatus(rawValue: r.statusRaw)?.keepsStreak == true)
        }
        // Today counts if at least 1 prayer done and none missed
        var streak    = todayPrayed.isEmpty ? 0 : 1
        var day       = cal.date(byAdding: .day, value: -1, to: today)!

        while day >= cap {
            let records = byDay[day] ?? []
            let prayed  = records.filter { r in
                guard let p = Prayer(rawValue: r.prayerRaw) else { return false }
                return p.isPrayer && (PrayerTrackerStatus(rawValue: r.statusRaw)?.keepsStreak == true)
            }
            guard prayed.count >= 5 else { break }
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }

        let streakFrom = cal.date(byAdding: .day, value: 1, to: day)!
        return StreakResult(days: streak, from: streakFrom, to: today)
    }

    @MainActor
    func getMaxStreak() throws -> StreakResult {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let cap   = cal.date(byAdding: .day, value: -365, to: today)!

        // One query — full year of records
        let descriptor = FetchDescriptor<PrayerRecordModel>(
            predicate: #Predicate { $0.prayerTime >= cap },
            sortBy: [SortDescriptor(\.prayerTime)]
        )
        let all = try container.mainContext.fetch(descriptor)
        let byDay = Dictionary(grouping: all) { cal.startOfDay(for: $0.prayerTime) }

        // Walk day by day oldest to newest, track longest consecutive run
        var maxDays = 0; var maxFrom = today; var maxTo = today
        var run = 0; var runFrom = today
        var day = cap

        while day <= today {
            let records = byDay[day] ?? []
            let prayed = records.filter { r in
                guard let p = Prayer(rawValue: r.prayerRaw) else { return false }
                return p.isPrayer && (PrayerTrackerStatus(rawValue: r.statusRaw)?.keepsStreak == true)
            }
            if prayed.count >= 5 {
                if run == 0 { runFrom = day }
                run += 1
                if run > maxDays { maxDays = run; maxFrom = runFrom; maxTo = day }
            } else {
                run = 0
            }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }

        return StreakResult(days: maxDays, from: maxFrom, to: maxTo)
    }
}
