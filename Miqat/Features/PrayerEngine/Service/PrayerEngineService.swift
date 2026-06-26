import Foundation
import Adhan

protocol PrayerEngineServiceProtocol {
    func calculateTimes(
        for date: Date,
        referenceDate: Date?,
        location: Location,
        settings: PrayerCalculationSettings
    ) -> [PrayerEntry]

    func prayers(from startDate: Date, to endDate: Date, location: Location, settings: PrayerCalculationSettings) -> [(Prayer, Date)]

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> Prayer?
    func nextPrayer(from entries: [PrayerEntry], at date: Date) -> PrayerEntry?
}

/// Wraps Adhan-Swift and maps our enums → Adhan models.
struct PrayerEngineService: PrayerEngineServiceProtocol {

    // MARK: - Public

    func calculateTimes(
        for date: Date,
        referenceDate: Date? = nil,
        location: Location,
        settings: PrayerCalculationSettings
    ) -> [PrayerEntry] {

        let coordinates = Coordinates(latitude: location.latitude,
                                      longitude: location.longitude)
        var params = settings.method.adhanParams
        params.madhab = settings.madhab.adhanMadhab
        params.highLatitudeRule = settings.highLatRule.adhanRule
        params.adjustments = PrayerAdjustments(
            fajr: settings.fajrAdjustment,
            sunrise: settings.sunriseAdjustment,
            dhuhr: settings.dhuhrAdjustment,
            asr: settings.asrAdjustment,
            maghrib: settings.maghribAdjustment,
            isha: settings.ishaAdjustment
        )
        params.rounding = settings.rounding.adhanRounding

        let cityTimezone   = TimeZone(identifier: location.timezone) ?? .current
        let dateComponents = date.gregorianComponents(in: cityTimezone)
        guard let prayerTimes = PrayerTimes(coordinates: coordinates,
                                            date: dateComponents,
                                            calculationParameters: params)
        else { return [] }

        let formatter = timeFormatter(for: date, timezone: cityTimezone)

        let statusRef = referenceDate ?? date
        let entries = Prayer.allCases.map { ref -> PrayerEntry in
            let adhanPrayer = ref.adhanPrayer
            let rawDate = prayerTimes.time(for: adhanPrayer)
            let status: PrayerTimeStatus = {
                let nextP    = prayerTimes.nextPrayer(at: statusRef)
                let currentP = prayerTimes.currentPrayer(at: statusRef)
                if let nextP, let nextRef = Prayer(adhanPrayer: nextP), ref == nextRef       { return .soon }
                if let currentP, let curRef = Prayer(adhanPrayer: currentP), ref == curRef   { return .current }
                return .upcoming
            }()
            let idx = Prayer.allCases.firstIndex(of: ref) ?? 0
            return PrayerEntry(
                id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", idx))")!,
                prayer: ref,
                time: formatter.string(from: rawDate),
                date: rawDate,
                status: status
            )
        }

        return entries
    }

    func prayers(from startDate: Date, to endDate: Date, location: Location, settings: PrayerCalculationSettings) -> [(Prayer, Date)] {
        let cal = Calendar.current
        var result: [(Prayer, Date)] = []
        var day = cal.startOfDay(for: startDate)
        let endDay = cal.startOfDay(for: endDate)
        while day <= endDay {
            let entries = calculateTimes(for: day, referenceDate: endDate, location: location, settings: settings)
            result += entries.compactMap { e in e.date.map { (e.prayer, $0) } }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return result.sorted { $0.1 < $1.1 }
    }

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> Prayer? {
        entries.first(where: { $0.status == .current })?.prayer
    }

    func nextPrayer(from entries: [PrayerEntry], at date: Date) -> PrayerEntry? {
        entries.first { entry in
            guard let entryDate = entry.date else { return false }
            return entry.status == .soon || (entry.status == .upcoming && entryDate > date)
        }
    }
}

// MARK: - Helpers

private extension PrayerEngineService {
    func timeFormatter(for baseDate: Date, timezone: TimeZone = .current) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        fmt.timeZone = timezone
        return fmt
    }
}
