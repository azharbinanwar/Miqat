import Foundation

protocol SettingsStorageProtocol {
    func load() -> AppSettings?
    func save(_ settings: AppSettings)
}

final class UserDefaultsStorage: SettingsStorageProtocol {
    private let key = Keys.Defaults.settings

    func load() -> AppSettings? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
