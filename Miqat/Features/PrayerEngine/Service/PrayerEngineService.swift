import Foundation
import Adhan

protocol PrayerEngineServiceProtocol {
    func calculateTimes(
        for date: Date,
        location: Location,
        settings: PrayerCalculationSettings
    ) -> [PrayerEntry]

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> ReferenceTime?
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

        let dateComponents = date.gregorianUTCComponents
        guard let prayerTimes = PrayerTimes(coordinates: coordinates,
                                            date: dateComponents,
                                            calculationParameters: params)
        else { return [] }

        let formatter = timeFormatter(for: date)

        var entries = ReferenceTime.allCases.map { ref -> PrayerEntry in
            let adhanPrayer = ref.adhanPrayer
            let rawDate = prayerTimes.time(for: adhanPrayer)
            let status: PrayerStatus = {
                guard let nextP = prayerTimes.nextPrayer(at: date),
                      let currentP = prayerTimes.currentPrayer(at: date)
                else { return .upcoming }
                let nextRef = ReferenceTime(adhanPrayer: nextP)
                let currentRef = ReferenceTime(adhanPrayer: currentP)
                if ref == nextRef { return .alert }
                if ref == currentRef { return .current }
                if rawDate < date { return .passed }
                return .upcoming
            }()
            return PrayerEntry(
                id: UUID(),
                referenceTime: ref,
                time: formatter.string(from: rawDate),
                date: rawDate,
                madhab: settings.madhab.rawValue,
                status: status
            )
        }

        // Mark remaining upcoming as .current if one passed recently
        if let currentAdhanPrayer = prayerTimes.currentPrayer(at: date),
           let currentRef = ReferenceTime(adhanPrayer: currentAdhanPrayer) {
            for i in entries.indices where entries[i].referenceTime == currentRef {
                entries[i].status = PrayerStatus.current
            }
        }

        return entries
    }

    func currentPrayer(from entries: [PrayerEntry], at date: Date) -> ReferenceTime? {
        entries.first(where: { $0.status == .current })?.referenceTime
    }

    func nextPrayer(from entries: [PrayerEntry], at date: Date) -> PrayerEntry? {
        entries.first(where: { $0.status == .alert || $0.status == .upcoming })
    }
}

// MARK: - Helpers

private extension PrayerEngineService {
    func timeFormatter(for baseDate: Date) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        // Use the timezone that the baseDate carries, else system
        if baseDate != baseDate { _ = () } // silence unused warning; placeholder
        return fmt
    }
}
