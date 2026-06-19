import SwiftUI

enum MockPrayerData {
    static let entries: [PrayerEntry] = [
        PrayerEntry.mock(referenceTime: .fajr,    time: "4:18 AM",  status: .prayed),
        PrayerEntry.mock(referenceTime: .sunrise, time: "5:47 AM",  status: .passed),
        PrayerEntry.mock(referenceTime: .dhuhr,   time: "12:08 PM", status: .prayed),
        PrayerEntry.mock(referenceTime: .asr,     time: "4:42 PM",  status: .current, isCurrent: true),
        PrayerEntry.mock(referenceTime: .maghrib, time: "7:21 PM",  status: .alert,   isAlert: true),
        PrayerEntry.mock(referenceTime: .isha,    time: "8:54 PM",  status: .upcoming),
    ]

    static let nextPrayer     = "Asr"
    static let nextPrayerTime = "4:42 PM"
    static let countdown      = "1:24"
    static let hijriDate      = "21 Dhul Hijjah 1447"
    static let fullDate       = "Thursday, 18 June 2026"
    static let location       = "Lahore, PK"
    static let streak         = 12
    static let todayPrayed    = 2
    static let todayTotal     = 5
    static let sunrise        = "5:47 AM"
    static let sunset         = "7:21 PM"
}
