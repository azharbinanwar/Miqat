import SwiftUI

// MARK: - Floating Panel View

struct FloatingPanelView: View {
    let prayerVM: PrayerTimeViewModel
    var onOpenSettings: () -> Void = {}
    @Environment(SettingsViewModel.self)         private var settingsVM
    @Environment(HijriCalendarViewModel.self)    private var hijriVM
    @Environment(PrayerTrackerViewModel.self)    private var trackerVM
    @State private var showContextMenu = false
    @State private var locationVM = LocationViewModel.shared
    private let currentHour = Calendar.current.component(.hour, from: Date())

    private var widgetSize: FloatingPanelSize { settingsVM.settings.floatingPanelSize }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: widgetSize.cornerRadius)
                .fill(timeGradient)
                .shadow(color: .black.opacity(0.45), radius: 32, x: 0, y: 16)

            switch widgetSize {
            case .small:  smallLayout
            case .medium: mediumLayout
            case .large:  largeLayout
            }
        }
        .frame(width: widgetSize.panelSize.width, height: widgetSize.panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: widgetSize.cornerRadius))
        .animation(.spring(duration: 0.3), value: widgetSize)
        .onLongPressGesture(minimumDuration: 0.5) { showContextMenu = true }
        .popover(isPresented: $showContextMenu, arrowEdge: .trailing) {
            FloatingPanelContextMenu(activePeriod: activePeriod, onOpenSettings: {
                showContextMenu = false
                onOpenSettings()
            })
            .environment(settingsVM)
        }
    }

    // MARK: Small layout (260 × 100)
    private var smallLayout: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT · \((prayerVM.nextPrayerEntry?.label ?? "--").uppercased())")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1.5)
                Text(prayerVM.countdownText)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundStyle(heroCountdownColor)
                Text(prayerVM.nextPrayerEntry?.time ?? "--:--")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            if activePeriod.isPrayer {
                IPrayedButton(prayer: activePeriod, date: Date(), compact: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Medium layout (320 × 390) — hero + list
    private var mediumLayout: some View {
        VStack(spacing: 0) {
            heroSection
            Divider().opacity(0.15).padding(.horizontal, 16)
            prayerList
        }
    }

    // MARK: Large layout (320 × 510) — header + hero + list
    private var largeLayout: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.15).padding(.horizontal, 16)
            heroSection
            Divider().opacity(0.15).padding(.horizontal, 16)
            prayerList
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(hijriVM.today.formatted)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(locationVM.activeCityName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColor.softAmber)
                    Text("\(trackerVM.currentStreak)d")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.12), in: Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(trackerVM.todayCount == 5 ? AppColor.softGreen : .white.opacity(0.6))
                    Text("\(trackerVM.todayCount)/5")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    // MARK: Hero countdown section
    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("NEXT · \((prayerVM.nextPrayerEntry?.label ?? "--").uppercased())")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            Text(prayerVM.countdownText)
                .font(.system(size: 52, weight: .heavy, design: .monospaced))
                .foregroundStyle(heroCountdownColor)

            Text(prayerVM.nextPrayerEntry?.time ?? "--:--")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))

            if activePeriod.isPrayer {
                IPrayedButton(prayer: activePeriod, date: Date())
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 18)
    }

    // MARK: Prayer list — identical to popup
    private var prayerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(prayerVM.displayEntries.enumerated()), id: \.element.id) { index, entry in
                PopoverPrayerRow(
                    entry: entry,
                    countdown: prayerVM.countdownText,
                    trackerStatus: trackerVM.records(for: prayerVM.displayDate).first(where: { $0.prayer == entry.prayer })?.status
                )
                if index < prayerVM.displayEntries.count - 1 {
                    Divider()
                        .padding(.leading, 46)
                        .opacity(0.08)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Gradient — mirrors PopoverView exactly
    private var activePeriod: Prayer {
        prayerVM.currentPrayer ?? prayerVM.nextPrayerEntry?.prayer ?? hourFallback
    }

    private var hourFallback: Prayer {
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
        LinearGradient(colors: activePeriod.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var timeAccent: Color { activePeriod.color }

    private var heroCountdownColor: Color {
        let mins = minutesFromCountdown(prayerVM.countdownText)
        if mins <= 20 { return AppColor.softRed }
        if mins <= 30 { return AppColor.softAmber }
        return .white
    }

    private func minutesFromCountdown(_ s: String) -> Int {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        switch parts.count {
        case 3: return parts[0] * 60 + parts[1]
        case 2: return parts[0]
        default: return 999
        }
    }
}
