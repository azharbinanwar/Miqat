import Foundation

protocol PrayerTrackerRepository {
    func save(_ record: PrayerRecord) throws
    func update(_ record: PrayerRecord) throws
    func records(for date: Date) throws -> [PrayerRecord]
    func records(from: Date, to: Date) throws -> [PrayerRecord]
    func delete(id: UUID) throws
    func deleteAll() throws

    /// Days since the last missed prayer — how long the user has been consistent
    func getCurrentStreak() throws -> StreakResult

    /// Longest unbroken run in full history
    func getMaxStreak() throws -> StreakResult
}
