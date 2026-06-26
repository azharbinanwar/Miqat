import SwiftUI

struct BottomStatsBar: View {
    @Environment(PrayerTimeViewModel.self)    private var prayerVM
    @Environment(PrayerTrackerViewModel.self) private var trackerVM

    private var sunriseTime: String {
        prayerVM.displayEntries.first(where: { $0.prayer == .sunrise })?.time ?? "--:--"
    }
    private var sunsetTime: String {
        prayerVM.displayEntries.first(where: { $0.prayer == .maghrib })?.time ?? "--:--"
    }

    var body: some View {
        HStack(spacing: 0) {
            statItem(icon: "flame.fill", iconColor: Prayer.sunrise.color,
                     label: "Streak", value: "\(trackerVM.currentStreak)d")

            Divider().frame(height: 28)

            statItem(icon: "checkmark.circle.fill", iconColor: Prayer.fajr.color,
                     label: "Today", value: "\(trackerVM.todayCount)/5 prayed",
                     valueColor: trackerVM.todayCount == 5 ? AppColor.softGreen : AppColor.alert)

            Divider().frame(height: 28)

            statItem(icon: "sunrise.fill", iconColor: Prayer.sunrise.color,
                     label: "Sunrise", value: sunriseTime)

            Divider().frame(height: 28)

            statItem(icon: "sunset.fill", iconColor: Prayer.maghrib.color,
                     label: "Sunset", value: sunsetTime)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(VisualEffect(material: .headerView, blendingMode: .withinWindow))
        .overlay(Divider(), alignment: .top)
    }

    private func statItem(icon: String, iconColor: Color, label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(valueColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
