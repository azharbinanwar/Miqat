import SwiftUI

struct BottomStatsBar: View {
    var body: some View {
        HStack(spacing: 0) {
            statItem(icon: "flame.fill", iconColor: AppColor.amber,
                     label: "Streak", value: "\(MockPrayerData.streak) days")

            Divider().frame(height: 28)

            statItem(icon: "checkmark.circle.fill", iconColor: AppColor.teal,
                     label: "Today", value: "\(MockPrayerData.todayPrayed)/\(MockPrayerData.todayTotal) prayed",
                     valueColor: AppColor.alert)

            Divider().frame(height: 28)

            statItem(icon: "sunrise.fill", iconColor: AppColor.amber,
                     label: "Sunrise", value: MockPrayerData.sunrise)

            Divider().frame(height: 28)

            statItem(icon: "sunset.fill", iconColor: AppColor.amber,
                     label: "Sunset", value: MockPrayerData.sunset)
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
