import Foundation

struct ThemeSettings: Codable {
    var appTheme: AppTheme       = .system
    var accentColorIndex: Int    = 0
}
