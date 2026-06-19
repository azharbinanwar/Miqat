import SwiftUI

// MARK: - Generic Tiles

// One generic prayer row tile for the widget list
struct WidgetPrayerRow: View {
    let entry: PrayerEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.referenceTime.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(rowIconColor)
                .frame(width: 16)

            Text(entry.referenceTime.rawValue)
                .font(.system(size: 13, weight: entry.isCurrent ? .semibold : .regular))
                .foregroundStyle(rowTextColor)

            Spacer()

            Text(entry.time)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(rowTimeColor)

            statusDot
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(entry.isCurrent ? Color.white.opacity(0.1) : Color.clear)
    }

    private var rowIconColor: Color {
        entry.isCurrent ? .white :
        entry.status == .prayed || entry.status == .passed ? .white.opacity(0.3) : .white.opacity(0.6)
    }

    private var rowTextColor: Color {
        entry.isCurrent ? .white :
        entry.status == .prayed || entry.status == .passed ? .white.opacity(0.35) : .white.opacity(0.75)
    }

    private var rowTimeColor: Color {
        entry.isAlert   ? AppColor.softRed :
        entry.isCurrent ? .white : .white.opacity(0.5)
    }

    @ViewBuilder
    private var statusDot: some View {
        switch entry.status {
        case .prayed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        case .current:
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
        case .alert:
            Circle()
                .fill(AppColor.softRed)
                .frame(width: 6, height: 6)
        default:
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Widget View

struct WidgetView: View {
    @State private var prayed = false
    @State private var currentHour = Calendar.current.component(.hour, from: Date())

    var body: some View {
        ZStack {
            // Time-of-day gradient background
            RoundedRectangle(cornerRadius: 24)
                .fill(timeGradient)
                .shadow(color: .black.opacity(0.45), radius: 32, x: 0, y: 16)

            VStack(spacing: 0) {
                header
                Divider().opacity(0.15).padding(.horizontal, 16)
                heroSection
                Divider().opacity(0.15).padding(.horizontal, 16)
                prayerList
                Divider().opacity(0.15).padding(.horizontal, 16)
                footer
            }
        }
        .frame(width: 320, height: 560)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(MockPrayerData.hijriDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(MockPrayerData.location)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColor.softAmber)
                Text("\(MockPrayerData.streak)d")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: Hero countdown section
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("NEXT · \(MockPrayerData.nextPrayer.uppercased())")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            Text(MockPrayerData.countdown)
                .font(.system(size: 52, weight: .heavy, design: .monospaced))
                .foregroundStyle(.white)

            Text(MockPrayerData.nextPrayerTime)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))

            Button {
                withAnimation(.spring(duration: 0.25)) { prayed.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: prayed ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                    Text(prayed ? "Prayed ✓" : "I Prayed")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(prayed ? timeAccent : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(prayed ? .white : .white.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.vertical, 18)
    }

    // MARK: Prayer list — generic WidgetPrayerRow per entry
    private var prayerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(MockPrayerData.entries.enumerated()), id: \.element.id) { index, entry in
                WidgetPrayerRow(entry: entry)
                if index < MockPrayerData.entries.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                        .opacity(0.08)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Footer
    private var footer: some View {
        HStack {
            // Madhab pill
            HStack(spacing: 4) {
                Text("Hanafi")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.1), in: Capsule())

            Spacer()

            // Today count
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(i < MockPrayerData.todayPrayed ? Color.white : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            // Settings icon
            Button { } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(7)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Time-of-day gradient — driven by prayer period, not raw hour
    private var approximatePeriod: ReferenceTime {
        switch currentHour {
        case 3..<6:   return .fajr
        case 6..<8:   return .sunrise
        case 8..<13:  return .dhuhr
        case 13..<17: return .asr
        case 17..<20: return .maghrib
        default:      return .isha
        }
    }

    private var timeGradient: LinearGradient {
        LinearGradient(colors: approximatePeriod.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var timeAccent: Color {
        approximatePeriod.color
    }
}
