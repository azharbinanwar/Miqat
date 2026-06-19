import SwiftUI

enum AccentColor {
    static let options: [(name: String, color: Color)] = [
        ("Teal",   AppColor.accentTeal),
        ("Purple", AppColor.accentPurple),
        ("Gold",   AppColor.accentGold),
        ("Blue",   AppColor.accentBlue),
    ]

    static var current: Color {
        // Read from new AppSettings JSON first
        if let data = UserDefaults.standard.data(forKey: Keys.Defaults.settings),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            let index = settings.accentColorIndex
            guard index >= 0, index < options.count else { return options[0].color }
            return options[index].color
        }
        // Fallback to old standalone key
        let index = UserDefaults.standard.integer(forKey: Keys.Defaults.accentColorIndex)
        guard index >= 0, index < options.count else { return options[0].color }
        return options[index].color
    }

    static func save(index: Int) {
        UserDefaults.standard.set(index, forKey: Keys.Defaults.accentColorIndex)
    }
}
