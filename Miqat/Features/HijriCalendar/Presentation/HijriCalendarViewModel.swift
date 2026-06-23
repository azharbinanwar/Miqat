import Foundation

@Observable
final class HijriCalendarViewModel {
    private(set) var today: HijriDate
    private let repo = HijriCalendarRepository()
    private var midnightTimer: Timer?

    init(offset: Int = 0) {
        today = repo.today(offset: offset)
        scheduleMidnightRefresh(offset: offset)
    }

    func update(offset: Int) {
        today = repo.today(offset: offset)
        midnightTimer?.invalidate()
        scheduleMidnightRefresh(offset: offset)
    }

    private func scheduleMidnightRefresh(offset: Int) {
        guard let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) else { return }

        midnightTimer = Timer(fire: nextMidnight, interval: 86400, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.today = self.repo.today(offset: offset)
        }
        RunLoop.main.add(midnightTimer!, forMode: .common)
    }
}
