import Foundation

struct PrayerCalculationSettings: Codable, Equatable {
    var method: CalculationMethod            = .mwl
    var madhab: Madhab                       = .hanafi
    var highLatRule: HighLatRule             = .middleNight
    var fajrAdjustment: Int                  = 0
    var sunriseAdjustment: Int               = 0
    var dhuhrAdjustment: Int                 = 0
    var asrAdjustment: Int                   = 0
    var maghribAdjustment: Int               = 0
    var ishaAdjustment: Int                  = 0
    var rounding: AdhanRoundingStyle         = .nearest

    static let `default` = PrayerCalculationSettings()
}

enum AdhanRoundingStyle: String, Codable, CaseIterable {
    case nearest = "nearest"
    case up      = "up"
    case none    = "none"
}
