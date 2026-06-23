import Foundation

@Observable
final class PrayerTimeViewModel {
    var state: AsyncState<[PrayerEntry]> = .idle
    private(set) var liveNow: Date = Date()

    private let service: PrayerEngineServiceProtocol
    private var location: Location?
    private var settings: PrayerCalculationSettings
    private var timer: Timer?
    private var tomorrowFajr: PrayerEntry?
    private var lastMinute = -1
    private var locationObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    init(service: PrayerEngineServiceProtocol = ServiceLocator.shared.resolve(PrayerEngineServiceProtocol.self),
         settings: PrayerCalculationSettings = .default) {
        self.service = service
        self.settings = settings
    }

    // MARK: - Timer

    func startLiveUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        locationObserver = NotificationCenter.default.addObserver(
            forName: .locationDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.reloadToday()
        }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.reloadToday()
        }
    }

    func stopLiveUpdates() {
        timer?.invalidate()
        timer = nil
        if let observer = locationObserver {
            NotificationCenter.default.removeObserver(observer)
            locationObserver = nil
        }
        if let observer = settingsObserver {
            NotificationCenter.default.removeObserver(observer)
            settingsObserver = nil
        }
    }

    private func tick() {
        liveNow = Date()
        let minute = Calendar.current.component(.minute, from: liveNow)
        if minute != lastMinute {
            lastMinute = minute
            reloadToday()
        }
    }

    // MARK: - Load

    func load(for date: Date = Date(), location: Location?) {
        guard let location else {
            state = .failure("No location set")
            return
        }
        self.location = location
        lastMinute = Calendar.current.component(.minute, from: date)
        state = .loading
        let result = service.calculateTimes(for: date, location: location, settings: settings)
        state = .success(result)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        let tomorrowEntries = service.calculateTimes(for: tomorrow, location: location, settings: settings)
        tomorrowFajr = tomorrowEntries.first(where: { $0.prayer == .fajr })
    }

    func reloadToday() {
        let repo = ServiceLocator.shared.resolve(LocationRepository.self)
        let freshLocation = repo.getActiveLocation() ?? location ?? Location.presets[0]
        location = freshLocation
        load(for: Date(), location: freshLocation)
    }

    // MARK: - Queries

    var entries: [PrayerEntry] {
        guard case let .success(items) = state else { return [] }
        return items
    }

    var currentPrayer: Prayer? {
        service.currentPrayer(from: entries, at: liveNow)
    }

    var nextPrayerEntry: PrayerEntry? {
        service.nextPrayer(from: entries, at: liveNow) ?? tomorrowFajr
    }

    var countdownText: String {
        guard let date = nextPrayerEntry?.date else { return "--:--:--" }
        return TimeInterval.formatCountdown(date.timeIntervalSince(liveNow))
    }

    // MARK: - Settings updates

    func update(settings: PrayerCalculationSettings) {
        self.settings = settings
        reloadToday()
    }

    func update(location: Location?) {
        self.location = location
        reloadToday()
    }
}
