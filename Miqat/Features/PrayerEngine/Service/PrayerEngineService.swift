import Foundation
import Adhan

protocol PrayerEngineServiceProtocol {
    func calculateTimes(
        for date: Date,
        location: Location,
        settings: PrayerCalculationSettings
    ) -> [PrayerEntry]

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> Prayer?
    func nextPrayer(from entries: [PrayerEntry], at date: Date) -> PrayerEntry?
}

/// Wraps Adhan-Swift and maps our enums → Adhan models.
struct PrayerEngineService: PrayerEngineServiceProtocol {

    // MARK: - Public

    func calculateTimes(
        for date: Date,
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

        let dateComponents = date.gregorianLocalComponents
        guard let prayerTimes = PrayerTimes(coordinates: coordinates,
                                            date: dateComponents,
                                            calculationParameters: params)
        else { return [] }

        let formatter = timeFormatter(for: date)

        let entries = Prayer.allCases.map { ref -> PrayerEntry in
            let adhanPrayer = ref.adhanPrayer
            let rawDate = prayerTimes.time(for: adhanPrayer)
            let status: PrayerStatus = {
                let nextP    = prayerTimes.nextPrayer(at: date)
                let currentP = prayerTimes.currentPrayer(at: date)
                if let nextP, let nextRef = Prayer(adhanPrayer: nextP), ref == nextRef       { return .alert }
                if let currentP, let curRef = Prayer(adhanPrayer: currentP), ref == curRef   { return .current }
                if rawDate < date { return .passed }
                return .upcoming
            }()
            let idx = Prayer.allCases.firstIndex(of: ref) ?? 0
            return PrayerEntry(
                id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", idx))")!,
                prayer: ref,
                time: formatter.string(from: rawDate),
                date: rawDate,
                madhab: settings.madhab.rawValue,
                status: status
            )
        }

        return entries
    }

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> Prayer? {
        entries.first(where: { $0.status == .current })?.prayer
    }

    func nextPrayer(from entries: [PrayerEntry], at date: Date) -> PrayerEntry? {
        entries.first { entry in
            guard let entryDate = entry.date else { return false }
            let statusOk = entry.status == .alert || entry.status == .upcoming
            return statusOk && entryDate > date
        }
    }
}

// MARK: - Helpers

private extension PrayerEngineService {
    func timeFormatter(for baseDate: Date) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        fmt.timeZone = .current
        return fmt
    }
}
