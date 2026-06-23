import Foundation

protocol ThemeRepository {
    func load() -> ThemeSettings
    func save(_ settings: ThemeSettings)
}

final class UserDefaultsThemeRepository: ThemeRepository {
    private let key = "dev.miqat.themeSettings"

    func load() -> ThemeSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(ThemeSettings.self, from: data)
        else { return ThemeSettings() }
        return settings
    }

    func save(_ settings: ThemeSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
