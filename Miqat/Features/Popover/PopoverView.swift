import SwiftUI

// MARK: - Generic Tile

struct PopoverPrayerRow: View {
    let entry: PrayerEntry
    let countdown: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.prayer.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(rowIconColor)
                .frame(width: 18)

            Text(entry.prayer.rawValue)
                .font(.system(size: 13, weight: entry.isCurrent ? .semibold : .regular))
                .foregroundStyle(rowTextColor)

            Spacer()

            if entry.isCurrent {
                Text(countdown)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(countdownColor)
            } else {
                Text(entry.time)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(rowTimeColor)
            }

            statusDot
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(entry.isCurrent ? Color.white.opacity(0.1) : Color.clear)
    }

    private var countdownColor: Color {
        let mins = minutesFromCountdown(countdown)
        if mins <= 20 { return Color(hex: "#FCA5A5") }
        if mins <= 30 { return Color(hex: "#FCD34D") }
        return .white
    }

    private var rowIconColor: Color {
        entry.isCurrent ? .white :
        entry.status == .prayed || entry.status == .passed ? .white.opacity(0.3) : .white.opacity(0.55)
    }

    private var rowTextColor: Color {
        entry.isCurrent ? .white :
        entry.status == .prayed || entry.status == .passed ? .white.opacity(0.3) : .white.opacity(0.75)
    }

    private var rowTimeColor: Color {
        entry.status == .prayed || entry.status == .passed ? .white.opacity(0.3) : .white.opacity(0.55)
    }

    @ViewBuilder
    private var statusDot: some View {
        switch entry.status {
        case .prayed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
        case .current:
            Circle().fill(countdownColor).frame(width: 6, height: 6)
        default:
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1).frame(width: 6, height: 6)
        }
    }

    private func minutesFromCountdown(_ s: String) -> Int {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return 999 }
        return parts[0] * 60 + parts[1]
    }
}

// MARK: - Popover View

struct PopoverView: View {
    @State private var madhab: Madhab  = .hanafi
    @State private var prayed          = false
    @State private var showLocations   = false
    @State private var activeLocation  = "London, UK"

    private let savedLocations = ["London, UK", "Manchester, UK", "Birmingham, UK", "Masjid, UK"]
    private let currentHour = Calendar.current.component(.hour, from: Date())

    var body: some View {
        ZStack {
            Rectangle().fill(timeGradient).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().opacity(0.15)
                countdownHero
                Divider().opacity(0.15)
                prayerList
                Divider().opacity(0.15)
                footer
            }
        }
        .frame(width: 320)
        .fixedSize(horizontal: true, vertical: true)
        .animation(.spring(duration: 0.22), value: showLocations)
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(MockPrayerData.hijriDate)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                Text(activeLocation)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Button { } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(7)
                    .background(.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Open Miqat")
        }
        .padding(.horizontal, 14)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: Countdown hero
    private var countdownHero: some View {
        VStack(spacing: 4) {
            Text("NEXT · \(MockPrayerData.nextPrayer.uppercased())")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)

            Text(MockPrayerData.countdown)
                .font(.system(size: 38, weight: .heavy, design: .monospaced))
                .foregroundStyle(heroCountdownColor)

            Button {
                withAnimation(.spring(duration: 0.2)) { prayed.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: prayed ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 12))
                    Text(prayed ? "Prayed ✓" : "I Prayed")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(prayed ? prayerAccentColor : Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(prayed ? .white : .white.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.vertical, 10)
    }

    // MARK: Prayer list
    private var prayerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(MockPrayerData.entries.enumerated()), id: \.element.id) { index, entry in
                PopoverPrayerRow(entry: entry, countdown: MockPrayerData.countdown)
                if index < MockPrayerData.entries.count - 1 {
                    Divider().padding(.leading, 46).opacity(0.08)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 0) {
                    footerPill(Madhab.hanafi.rawValue, selected: madhab == .hanafi) { madhab = .hanafi }
                    footerPill(Madhab.shafi.rawValue,  selected: madhab == .shafi)  { madhab = .shafi  }
                }
                .background(.white.opacity(0.1), in: Capsule())

                Spacer()

                Button { } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(7)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.spring(duration: 0.2)) { showLocations.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(activeLocation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: showLocations ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if showLocations {
                locationDropdown
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 24)
    }

    // MARK: Location dropdown
    private var locationDropdown: some View {
        VStack(spacing: 0) {
            ForEach(savedLocations, id: \.self) { loc in
                Button {
                    withAnimation(.spring(duration: 0.18)) {
                        activeLocation = loc
                        showLocations  = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: activeLocation == loc ? "location.fill" : "location")
                            .font(.system(size: 11))
                            .foregroundStyle(activeLocation == loc ? Color(hex: "#0D9488") : .white.opacity(0.5))
                            .frame(width: 16)
                        Text(loc)
                            .font(.system(size: 12, weight: activeLocation == loc ? .semibold : .regular))
                            .foregroundStyle(activeLocation == loc ? .white : .white.opacity(0.65))
                        Spacer()
                        if activeLocation == loc {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "#0D9488"))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(activeLocation == loc ? Color.white.opacity(0.08) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if loc != savedLocations.last {
                    Divider().padding(.leading, 36).opacity(0.1)
                }
            }
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func footerPill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selected ? prayerAccentColor : .white.opacity(0.55))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? .white : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Colours
    private var heroCountdownColor: Color {
        let parts = MockPrayerData.countdown.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return .white }
        let mins = parts[0] * 60 + parts[1]
        if mins <= 20 { return Color(hex: "#FCA5A5") }
        if mins <= 30 { return Color(hex: "#FCD34D") }
        return .white
    }

    private var prayerAccentColor: Color {
        switch currentHour {
        case 3..<6:   return Color(hex: "#7C3AED")
        case 6..<8:   return Color(hex: "#D97706")
        case 8..<13:  return Color(hex: "#0D9488")
        case 13..<17: return Color(hex: "#D97706")
        case 17..<20: return Color(hex: "#9333EA")
        default:      return Color(hex: "#4F46E5")
        }
    }

    private var timeGradient: LinearGradient {
        let colors: [Color]
        switch currentHour {
        case 3..<6:   colors = [Color(hex: "#1E1B4B"), Color(hex: "#4C1D95")]
        case 6..<8:   colors = [Color(hex: "#92400E"), Color(hex: "#F59E0B")]
        case 8..<13:  colors = [Color(hex: "#0F766E"), Color(hex: "#06B6D4")]
        case 13..<17: colors = [Color(hex: "#92400E"), Color(hex: "#D97706")]
        case 17..<20: colors = [Color(hex: "#7C2D12"), Color(hex: "#9333EA")]
        default:      colors = [Color(hex: "#0F172A"), Color(hex: "#1E1B4B")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
