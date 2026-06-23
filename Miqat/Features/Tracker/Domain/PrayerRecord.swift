import Foundation

struct PrayerRecord: Identifiable, Codable {
    let id:         UUID
    let prayer:     Prayer
    let prayerTime: Date
    var status:     PrayerTrackerStatus
    var markedAt:   Date?

    init(prayer: Prayer, prayerTime: Date, status: PrayerTrackerStatus = .upcoming, markedAt: Date? = nil) {
        self.id         = UUID()
        self.prayer     = prayer
        self.prayerTime = prayerTime
        self.status     = status
        self.markedAt   = markedAt
    }
}
