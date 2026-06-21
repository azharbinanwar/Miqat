import Foundation

final class NotificationRepository {
    static let shared = NotificationRepository()
    private init() {}

    private enum Keys {
        static let prayerConfigs = "notif.prayerConfigs"
        static let allEnabled    = "notif.allEnabled"
        static let iPrayed       = "notif.iPrayed"
        static let snooze        = "notif.snooze"
        static let dnd           = "notif.dnd"
        static let mulkConfig    = "notif.mulkConfig"
        static let kahfConfig    = "notif.kahfConfig"
        static let jumuahConfig  = "notif.jumuahConfig"
    }

    private let defaults = UserDefaults.standard

    // MARK: Prayer configs

    func savePrayerConfigs(_ configs: [PrayerNotifConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            defaults.set(data, forKey: Keys.prayerConfigs)
        }
    }

    func loadPrayerConfigs() -> [PrayerNotifConfig] {
        guard let data = defaults.data(forKey: Keys.prayerConfigs),
              let configs = try? JSONDecoder().decode([PrayerNotifConfig].self, from: data)
        else { return defaultPrayerConfigs() }
        return configs
    }

    // MARK: General toggles

    func save(allEnabled: Bool)    { defaults.set(allEnabled, forKey: Keys.allEnabled) }
    func save(iPrayed: Bool)       { defaults.set(iPrayed,    forKey: Keys.iPrayed) }
    func save(snooze: Bool)        { defaults.set(snooze,     forKey: Keys.snooze) }
    func save(dnd: Bool)           { defaults.set(dnd,        forKey: Keys.dnd) }

    func loadAllEnabled() -> Bool  { defaults.object(forKey: Keys.allEnabled) as? Bool ?? true }
    func loadIPrayed()    -> Bool  { defaults.object(forKey: Keys.iPrayed)    as? Bool ?? true }
    func loadSnooze()     -> Bool  { defaults.object(forKey: Keys.snooze)     as? Bool ?? true }
    func loadDND()        -> Bool  { defaults.object(forKey: Keys.dnd)        as? Bool ?? true }

    // MARK: Surah / Friday configs

    func saveMulkConfig(_ config: SurahMulkConfig) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Keys.mulkConfig)
        }
    }

    func loadMulkConfig() -> SurahMulkConfig {
        guard let data = defaults.data(forKey: Keys.mulkConfig),
              let config = try? JSONDecoder().decode(SurahMulkConfig.self, from: data)
        else { return SurahMulkConfig() }
        return config
    }

    func saveKahfConfig(_ config: SurahKahfConfig) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Keys.kahfConfig)
        }
    }

    func loadKahfConfig() -> SurahKahfConfig {
        guard let data = defaults.data(forKey: Keys.kahfConfig),
              let config = try? JSONDecoder().decode(SurahKahfConfig.self, from: data)
        else { return SurahKahfConfig() }
        return config
    }

    func saveJumuahConfig(_ config: FridayJumuahConfig) {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Keys.jumuahConfig)
        }
    }

    func loadJumuahConfig() -> FridayJumuahConfig {
        guard let data = defaults.data(forKey: Keys.jumuahConfig),
              let config = try? JSONDecoder().decode(FridayJumuahConfig.self, from: data)
        else { return FridayJumuahConfig() }
        return config
    }

    // MARK: Defaults

    private func defaultPrayerConfigs() -> [PrayerNotifConfig] {
        [
            PrayerNotifConfig(referenceTime: .fajr,    enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
            PrayerNotifConfig(referenceTime: .dhuhr,   enabled: true, xMinutes: 20, atPrayerTime: false, zEnabled: true, zMinutes: 30, sound: .systemDefault),
            PrayerNotifConfig(referenceTime: .asr,     enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
            PrayerNotifConfig(referenceTime: .maghrib, enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 10, sound: .systemDefault),
            PrayerNotifConfig(referenceTime: .isha,    enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
        ]
    }
}
