import SwiftUI

@Observable
final class NotificationViewModel {
    // MARK: State

    var prayerConfigs: [PrayerNotifConfig]
    var allEnabled: Bool
    var iPrayedEnabled: Bool
    var snoozeEnabled: Bool
    var dndEnabled: Bool
    var mulkConfig: SurahMulkConfig
    var kahfConfig: SurahKahfConfig
    var jumuahConfig: FridayJumuahConfig

    // MARK: Dependencies

    private let repo     = NotificationRepository.shared
    private let service  = NotificationService.shared
    let notifManager     = NotificationManager.shared

    // Location + settings injected from AppDelegate after init
    var location: Location?
    var calculationSettings: PrayerCalculationSettings?

    // MARK: Init

    init() {
        prayerConfigs  = repo.loadPrayerConfigs()
        allEnabled     = repo.loadAllEnabled()
        iPrayedEnabled = repo.loadIPrayed()
        snoozeEnabled  = repo.loadSnooze()
        dndEnabled     = repo.loadDND()
        mulkConfig     = repo.loadMulkConfig()
        kahfConfig     = repo.loadKahfConfig()
        jumuahConfig   = repo.loadJumuahConfig()
    }

    // MARK: Reschedule entry points

    func rescheduleAll() {
        guard let loc = location, let s = calculationSettings else { return }
        Task { await service.scheduleAll(vm: self, location: loc, settings: s) }
    }

    func rescheduleIfNeeded() {
        guard let loc = location, let s = calculationSettings else { return }
        Task { await service.scheduleIfNeeded(vm: self, location: loc, settings: s) }
    }

    // MARK: Prayer config — surgical reschedule

    func updatePrayerConfig(_ config: PrayerNotifConfig) {
        guard let index = prayerConfigs.firstIndex(where: { $0.id == config.id }) else { return }
        prayerConfigs[index] = config
        repo.savePrayerConfigs(prayerConfigs)
        guard allEnabled, let loc = location, let s = calculationSettings else { return }
        Task { await service.schedulePrayer(config, location: loc, settings: s) }
    }

    // MARK: Master toggle

    func setAllEnabled(_ value: Bool) {
        allEnabled = value
        repo.save(allEnabled: value)
        if value { rescheduleAll() } else { service.cancelAll() }
    }

    // MARK: General toggles

    func setIPrayed(_ value: Bool) {
        iPrayedEnabled = value
        repo.save(iPrayed: value)
    }

    func setSnooze(_ value: Bool) {
        snoozeEnabled = value
        repo.save(snooze: value)
    }

    func setDND(_ value: Bool) {
        dndEnabled = value
        repo.save(dnd: value)
    }

    // MARK: Surah / Friday configs — surgical reschedule

    func updateMulkConfig(_ config: SurahMulkConfig) {
        mulkConfig = config
        repo.saveMulkConfig(config)
        guard allEnabled, let loc = location, let s = calculationSettings else { return }
        Task { await service.scheduleMulk(config, location: loc, settings: s) }
    }

    func updateKahfAnchor(_ anchorConfig: KahfAnchorConfig) {
        guard let index = kahfConfig.anchors.firstIndex(where: { $0.id == anchorConfig.id }) else { return }
        kahfConfig.anchors[index] = anchorConfig
        repo.saveKahfConfig(kahfConfig)
        guard allEnabled, let loc = location, let s = calculationSettings else { return }
        Task { await service.scheduleKahfAnchor(anchorConfig, location: loc, settings: s) }
    }

    func updateJumuahConfig(_ config: FridayJumuahConfig) {
        jumuahConfig = config
        repo.saveJumuahConfig(config)
        guard allEnabled, let loc = location, let s = calculationSettings else { return }
        Task { await service.scheduleJumuah(config, location: loc, settings: s) }
    }
}
