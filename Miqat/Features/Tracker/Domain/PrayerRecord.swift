import Foundation

struct PrayerRecord: Identifiable, Codable {
    let id:         UUID
    let prayer:     Prayer
    let prayerTime: Date
    var status:     PrayerTrackerStatus
    var markedAt:   Date?

    init(id: UUID = UUID(), prayer: Prayer, prayerTime: Date, status: PrayerTrackerStatus = .missed, markedAt: Date? = nil) {
        self.id         = id
        self.prayer     = prayer
        self.prayerTime = prayerTime
        self.status     = status
        self.markedAt   = markedAt
    }
}
