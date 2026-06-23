import Foundation

struct AppSettings: Codable, Equatable {
    // MARK: - Prayer Calculation
    var calculationMethod: CalculationMethod = .mwl
    var madhab: Madhab = .hanafi
    var highLatRule: HighLatRule = .middleNight
    var fajrAdjustment: Int = 0
    var sunriseAdjustment: Int = 0
    var dhuhrAdjustment: Int = 0
    var asrAdjustment: Int = 0
    var maghribAdjustment: Int = 0
    var ishaAdjustment: Int = 0
    var hijriAdjustment: Int = 0
    var rounding: AdhanRoundingStyle = .nearest

    // MARK: - Menu Bar
    var menuShowPrayerName: Bool = true
    var menuShowIcon: Bool = true
    var menuDisplay: MenuBarDisplay = .countdown
    var menuShowSeconds: Bool = true
    var orangeThreshold: Int = 30
    var redThreshold: Int = 20

    // MARK: - Appearance
    var appTheme: AppTheme = .system
    var accentColorIndex: Int = 0

    // MARK: - Startup
    var launchAtLogin: Bool = true
    var floatingPanelMode: FloatingPanelMode = .always
    var floatingPanelSize: FloatingPanelSize = .medium
    var openWindowOnLaunch: Bool = true
}

enum FloatingPanelMode: String, CaseIterable, Codable, Hashable {
    case off    = "Off"
    case normal = "Normal"
    case always = "Always"
}

enum FloatingPanelSize: String, CaseIterable, Codable, Hashable {
    case small  = "Small"
    case medium = "Medium"
    case large  = "Large"

    var shortLabel: String {
        switch self { case .small: return "S"; case .medium: return "M"; case .large: return "L" }
    }

    var panelSize: CGSize {
        switch self {
        case .small:  return CGSize(width: 320, height: 100)
        case .medium: return CGSize(width: 320, height: 480)
        case .large:  return CGSize(width: 320, height: 560)
        }
    }

    var cornerRadius: CGFloat { self == .small ? 14 : 16 }
}

// MARK: - Derived helpers

extension AppSettings {
    var prayerCalculationSettings: PrayerCalculationSettings {
        PrayerCalculationSettings(
            method: calculationMethod,
            madhab: madhab,
            highLatRule: highLatRule,
            fajrAdjustment: fajrAdjustment,
            sunriseAdjustment: sunriseAdjustment,
            dhuhrAdjustment: dhuhrAdjustment,
            asrAdjustment: asrAdjustment,
            maghribAdjustment: maghribAdjustment,
            ishaAdjustment: ishaAdjustment,
            rounding: rounding
        )
    }

    mutating func applyCalculationSettings(_ calc: PrayerCalculationSettings) {
        calculationMethod = calc.method
        madhab = calc.madhab
        highLatRule = calc.highLatRule
        fajrAdjustment = calc.fajrAdjustment
        sunriseAdjustment = calc.sunriseAdjustment
        dhuhrAdjustment = calc.dhuhrAdjustment
        asrAdjustment = calc.asrAdjustment
        maghribAdjustment = calc.maghribAdjustment
        ishaAdjustment = calc.ishaAdjustment
        rounding = calc.rounding
    }
}
