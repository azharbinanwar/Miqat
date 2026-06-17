import SwiftUI

struct BottomStatsBar: View {
    var body: some View {
        HStack(spacing: 0) {
            statItem(icon: "flame.fill", iconColor: Color(hex: "#F59E0B"),
                     label: "Streak", value: "\(MockPrayerData.streak) days")

            Divider().frame(height: 28)

            statItem(icon: "checkmark.circle.fill", iconColor: Color(hex: "#0D9488"),
                     label: "Today", value: "\(MockPrayerData.todayPrayed)/\(MockPrayerData.todayTotal) prayed",
                     valueColor: Color(hex: "#DC2626"))

            Divider().frame(height: 28)

            statItem(icon: "sunrise.fill", iconColor: Color(hex: "#F59E0B"),
                     label: "Sunrise", value: MockPrayerData.sunrise)

            Divider().frame(height: 28)

            statItem(icon: "sunset.fill", iconColor: Color(hex: "#F59E0B"),
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
