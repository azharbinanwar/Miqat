import SwiftUI

// MARK: - Generic Tile

struct PopoverPrayerRow: View {
    let entry: PrayerEntry
    let countdown: String

    private var timeStatus:    PrayerTimeStatus    { entry.timeStatus }
    private var trackerStatus: PrayerTrackerStatus { entry.trackerStatus }
    private var isCurrent: Bool { timeStatus == .current }
    private var isSoon:    Bool { timeStatus == .soon }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar — current only
            RoundedRectangle(cornerRadius: 2)
                .fill(isCurrent ? entry.referenceTime.color : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 8)

            HStack(spacing: 10) {
                // Prayer identity icon
                Image(systemName: entry.referenceTime.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(rowIconColor)
                    .frame(width: 18)

                // Prayer name
                Text(entry.label)
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(rowNameColor)

                Spacer()

                // Time status badge (NOW / SOON)
                if let label = timeStatus.badgeLabel {
                    Text(label)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            isCurrent ? .white.opacity(0.25) : timeStatus.badgeColor.opacity(0.35),
                            in: Capsule()
                        )
                }

                // Tracker badge (PRAYED / MISSED)
                if let label = trackerStatus.badgeLabel {
                    HStack(spacing: 3) {
                        Image(systemName: trackerStatus == .prayed ? "checkmark" : "xmark")
                            .font(.system(size: 7, weight: .bold))
                        Text(label)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(trackerStatus.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trackerStatus.badgeBackground, in: Capsule())
                }

                // Show prayer start time — countdown shown at top of popover only
                Text(entry.time)
                    .font(.system(size: 12, weight: isCurrent ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isCurrent ? countdownColor : rowTimeColor)

                // Tracker status icon
                Image(systemName: trackerStatus.icon)
                    .font(.system(size: isCurrent ? 8 : 13))
                    .foregroundStyle(
                        isCurrent
                            ? entry.referenceTime.color
                            : trackerStatus.color
                    )
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.vertical, 9)
        }
        .background {
            if isCurrent {
                entry.referenceTime.color.opacity(0.15)
            } else if trackerStatus == .prayed {
                AppColor.softGreen.opacity(0.07)
            } else if trackerStatus == .missed {
                AppColor.softRed.opacity(0.07)
            } else {
                Color.clear
            }
        }
    }

    // MARK: Colours

    private var rowIconColor: Color {
        switch timeStatus {
        case .current:  return entry.referenceTime.color
        case .soon:     return AppColor.softAmber
        default:        return .white.opacity(0.65)
        }
    }

    private var rowNameColor: Color {
        switch timeStatus {
        case .current:  return .white
        case .soon:     return .white
        default:        return .white.opacity(0.75)
        }
    }

    private var rowTimeColor: Color {
        .white.opacity(0.55)
    }

    private var countdownColor: Color {
        let mins = minutesFromCountdown(countdown)
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

// MARK: - Popover View

struct PopoverView: View {
    let prayerVM: PrayerTimeViewModel
    let settingsVM: SettingsViewModel
    @State private var prayed          = false
    @State private var showLocations = false
    @State private var vm            = LocationViewModel.shared
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
        .preferredColorScheme(appThemeColorScheme)
        .tint(AccentColor.current)
    }

    private var appThemeColorScheme: ColorScheme? {
        switch settingsVM.settings.appTheme {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(MockPrayerData.hijriDate)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                Text(vm.activeCityName)
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
            Text("NEXT · \(prayerVM.nextPrayerEntry?.label.uppercased() ?? "--")")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)

            Text(prayerVM.countdownText)
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
            ForEach(Array(prayerVM.entries.enumerated()), id: \.element.id) { index, entry in
                PopoverPrayerRow(entry: entry, countdown: prayerVM.countdownText)
                if index < prayerVM.entries.count - 1 {
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
                    footerPill(Madhab.hanafi.rawValue, selected: settingsVM.settings.madhab == .hanafi) { settingsVM.update { $0.madhab = .hanafi } }
                    footerPill(Madhab.shafi.rawValue,  selected: settingsVM.settings.madhab == .shafi)  { settingsVM.update { $0.madhab = .shafi  } }
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
                    Text(vm.activeCityName)
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
            ForEach(Array(vm.locations.enumerated()), id: \.element.id) { index, loc in
                Button {
                    withAnimation(.spring(duration: 0.18)) {
                        vm.setActive(loc)
                        showLocations = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: vm.activeLocationId == loc.id ? "location.fill" : "location")
                            .font(.system(size: 11))
                            .foregroundStyle(vm.activeLocationId == loc.id ? prayerAccentColor : .white.opacity(0.5))
                            .frame(width: 16)
                        Text(loc.city)
                            .font(.system(size: 12, weight: vm.activeLocationId == loc.id ? .semibold : .regular))
                            .foregroundStyle(vm.activeLocationId == loc.id ? .white : .white.opacity(0.65))
                        Spacer()
                        if vm.activeLocationId == loc.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(prayerAccentColor)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(vm.activeLocationId == loc.id ? Color.white.opacity(0.08) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if index < vm.locations.count - 1 {
                    Divider().padding(.leading, 36).opacity(0.1)
                }
            }
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func popoverMinutesFromCountdown(_ s: String) -> Int {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        switch parts.count {
        case 3: return parts[0] * 60 + parts[1]
        case 2: return parts[0]
        default: return 999
        }
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

    // MARK: Colours — driven by current prayer from the engine

    private var activePeriod: ReferenceTime {
        prayerVM.currentPrayer
            ?? prayerVM.nextPrayerEntry?.referenceTime
            ?? hourFallback
    }

    private var hourFallback: ReferenceTime {
        switch currentHour {
        case 3..<6:   return .fajr
        case 6..<8:   return .sunrise
        case 8..<13:  return .dhuhr
        case 13..<17: return .asr
        case 17..<20: return .maghrib
        default:      return .isha
        }
    }

    private var prayerAccentColor: Color { activePeriod.color }

    private var timeGradient: LinearGradient {
        LinearGradient(colors: activePeriod.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var heroCountdownColor: Color {
        let mins = popoverMinutesFromCountdown(prayerVM.countdownText)
        if mins <= 20 { return AppColor.softRed }
        if mins <= 30 { return AppColor.softAmber }
        return .white
    }
}
