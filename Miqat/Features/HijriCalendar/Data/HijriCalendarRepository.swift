import Foundation

struct HijriCalendarRepository {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en")
        return cal
    }()

    private static let formatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.locale = Locale(identifier: "en")
        fmt.dateFormat = "MMMM"
        return fmt
    }()

    func today(offset: Int = 0) -> HijriDate {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let comps = Self.calendar.dateComponents([.day, .month, .year], from: date)
        let monthName = Self.formatter.string(from: date)
        return HijriDate(
            day: comps.day ?? 1,
            month: comps.month ?? 1,
            monthName: monthName,
            year: comps.year ?? 1446
        )
    }
}
