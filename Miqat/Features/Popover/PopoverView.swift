import SwiftUI

// MARK: - Generic Tile

struct PopoverPrayerRow: View {
    let entry: PrayerEntry
    let countdown: String
    var trackerStatus: PrayerTrackerStatus?

    private var isCurrent: Bool { entry.status == .current }
    private var isSoon:    Bool { entry.status == .soon }
    private var isPrayed:  Bool { trackerStatus?.keepsStreak ?? false }
    private var isMissed:  Bool { trackerStatus == .missed }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar — current only
            RoundedRectangle(cornerRadius: 2)
                .fill(isCurrent ? entry.prayer.color : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 8)

            HStack(spacing: 0) {
                // Col 1: prayer icon — fixed
                Image(systemName: entry.prayer.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(rowIconColor)
                    .frame(width: 24, alignment: .center)

                // Col 2: prayer name + ripple dot if current
                HStack(spacing: 6) {
                    Text(entry.label)
                        .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(rowNameColor)
                    if isCurrent {
                        PulsingDot(color: entry.prayer.onColor, size: 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Col 3: tracker status or soon — fixed
                Group {
                    if isSoon {
                        Text("Soon")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColor.softAmber)
                    } else if let ts = trackerStatus, entry.prayer.isPrayer {
                        Image(systemName: ts.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(ts.color)
                    }
                }
                .frame(width: 36, alignment: .center)

                // Col 4: time — fixed
                Text(entry.time)
                    .font(.system(size: 12, weight: isCurrent ? .bold : .regular, design: .monospaced))
                    .foregroundStyle(isCurrent ? countdownColor : rowTimeColor)
                    .frame(width: 65, alignment: .trailing)
            }
            .padding(.leading, 8)
            .padding(.trailing, 14)
            .padding(.vertical, 9)
        }
        .background {
            if isCurrent { entry.prayer.color.opacity(0.15) }
        }
    }

    // MARK: Colours

    private var rowIconColor: Color {
        switch entry.status {
        case .current:  return entry.prayer.color
        case .soon:     return AppColor.softAmber
        case .upcoming: return .white.opacity(0.65)
        }
    }

    private var rowNameColor: Color {
        switch entry.status {
        case .current, .soon: return .white
        case .upcoming:       return .white.opacity(0.75)
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
    var onOpenApp: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    @Environment(HijriCalendarViewModel.self)     private var hijriVM
    @Environment(ThemeViewModel.self)             private var themeVM
    @Environment(PrayerTrackerViewModel.self)     private var trackerVM
    @State private var showLocations = false
    @State private var vm            = LocationViewModel.shared
    private let currentHour = Calendar.current.component(.hour, from: Date())

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(timeGradient)

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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(width: 320)
        .fixedSize(horizontal: true, vertical: true)
        .animation(.spring(duration: 0.22), value: showLocations)
        .preferredColorScheme(appThemeColorScheme)
        .tint(themeVM.accentColor)
    }

    private var appThemeColorScheme: ColorScheme? { themeVM.colorScheme }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(hijriVM.today.formatted)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                Text(vm.activeCityName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Button { onOpenApp() } label: {
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

            if activePeriod.isPrayer {
                IPrayedButton(prayer: activePeriod, date: Date())
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: Prayer list
    private var prayerList: some View {
        VStack(spacing: 0) {
            ForEach(Array(prayerVM.displayEntries.enumerated()), id: \.element.id) { index, entry in
                PopoverPrayerRow(
                    entry: entry,
                    countdown: prayerVM.countdownText,
                    trackerStatus: trackerVM.records(for: prayerVM.displayDate).first(where: { $0.prayer == entry.prayer })?.status
                )
                if index < prayerVM.displayEntries.count - 1 {
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

                Button { onOpenSettings() } label: {
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

    private var activePeriod: Prayer {
        prayerVM.currentPrayer
            ?? prayerVM.nextPrayerEntry?.prayer
            ?? hourFallback
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
