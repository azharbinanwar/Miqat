import SwiftUI

struct NextPrayerCard: View {
    @State private var iPrayed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: ReferenceTime.asr.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEXT PRAYER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)

                    Text(MockPrayerData.nextPrayer)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Text(MockPrayerData.nextPrayerTime)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer().frame(height: 4)

                    Button {
                        withAnimation(.spring(duration: 0.3)) { iPrayed.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: iPrayed ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 13, weight: .semibold))
                            Text(iPrayed ? "Prayed ✓" : "I Prayed")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(iPrayed ? ReferenceTime.asr.color : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iPrayed ? .white : .white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(MockPrayerData.countdown)
                        .font(.system(size: 52, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("hours remaining")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(24)
        }
        .frame(height: 140)
    }
}
