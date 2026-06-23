import Foundation

struct HijriDate {
    let day: Int
    let month: Int
    let monthName: String
    let year: Int

    var formatted: String { "\(day) \(monthName) \(year)" }
    var short: String { "\(day) \(monthName)" }
}
