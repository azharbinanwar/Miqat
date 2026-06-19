import SwiftUI

enum AccentColor {
    static let options: [(name: String, color: Color)] = [
        ("Teal",   Color(hex: "#0D9488")),
        ("Purple", Color(hex: "#7C3AED")),
        ("Gold",   Color(hex: "#D97706")),
        ("Blue",   Color(hex: "#2563EB")),
    ]

    static var current: Color {
        let index = UserDefaults.standard.integer(forKey: Keys.Defaults.accentColorIndex)
        guard index >= 0, index < options.count else { return options[0].color }
        return options[index].color
    }

    static func save(index: Int) {
        UserDefaults.standard.set(index, forKey: Keys.Defaults.accentColorIndex)
    }
}
