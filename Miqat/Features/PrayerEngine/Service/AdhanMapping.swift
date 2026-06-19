import Foundation
import Adhan

// MARK: - CalculationMethod → Adhan.CalculationMethod

extension CalculationMethod {
    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .mwl:          return .muslimWorldLeague
        case .isna:         return .northAmerica
        case .egypt:        return .egyptian
        case .makkah:       return .ummAlQura
        case .karachi:      return .karachi
        case .turkey:       return .turkey
        case .moonsighting: return .moonsightingCommittee
        case .singapore:    return .singapore
        case .dubai:        return .dubai
        case .tehran:       return .tehran
        }
    }

    var adhanParams: Adhan.CalculationParameters { adhanMethod.params }
}

// MARK: - Madhab → Adhan.Madhab

extension Madhab {
    var adhanMadhab: Adhan.Madhab {
        switch self {
        case .hanafi: return .hanafi
        case .shafi:  return .shafi
        }
    }
}

// MARK: - HighLatRule → Adhan.HighLatitudeRule

extension HighLatRule {
    var adhanRule: Adhan.HighLatitudeRule {
        switch self {
        case .middleNight:  return .middleOfTheNight
        case .seventhNight: return .seventhOfTheNight
        case .angleBased:   return .twilightAngle
        }
    }
}

// MARK: - Rounding

extension AdhanRoundingStyle {
    var adhanRounding: Adhan.Rounding {
        switch self {
        case .nearest: return .nearest
        case .up:      return .up
        case .none:    return .none
        }
    }
}

// MARK: - ReferenceTime ↔ Adhan.Prayer

extension ReferenceTime {
    var adhanPrayer: Adhan.Prayer {
        switch self {
        case .fajr:    return .fajr
        case .sunrise: return .sunrise
        case .dhuhr:   return .dhuhr
        case .asr:     return .asr
        case .maghrib: return .maghrib
        case .isha:    return .isha
        }
    }

    init?(adhanPrayer: Adhan.Prayer) {
        switch adhanPrayer {
        case .fajr:    self = .fajr
        case .sunrise: self = .sunrise
        case .dhuhr:   self = .dhuhr
        case .asr:     self = .asr
        case .maghrib: self = .maghrib
        case .isha:    self = .isha
        }
    }
}

// MARK: - Date → Gregorian UTC DateComponents

extension Date {
    var gregorianLocalComponents: DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        return cal.dateComponents([.year, .month, .day], from: self)
    }
}
