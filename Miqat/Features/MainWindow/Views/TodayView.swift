import SwiftUI

struct TodayView: View {
    @Environment(SettingsViewModel.self)         private var settingsVM
    @Environment(PrayerTimeViewModel.self)       private var prayerVM
    @Environment(PrayerTrackerViewModel.self)    private var trackerVM

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top row: next prayer card + quick stats
                    HStack(alignment: .top, spacing: 16) {
                        NextPrayerHeroCard(vm: prayerVM)
                        QuickStatsColumn(entries: prayerVM.displayEntries)
                    }
                    .padding(.horizontal, 24)

                    // Prayer times list
                    PrayerListCard(entries: prayerVM.displayEntries, trackerRecords: trackerVM.records(for: prayerVM.displayDate))
                        .padding(.horizontal, 24)

                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadPrayerTimes()
        }
        .onChange(of: settingsVM.settings.prayerCalculationSettings) { loadPrayerTimes() }
    }

    private func loadPrayerTimes() {
        prayerVM.update(settings: settingsVM.settings.prayerCalculationSettings)
        let repo = ServiceLocator.shared.resolve(LocationRepository.self)
        let location = repo.getActiveLocation() ?? Location.presets[0]
        prayerVM.load(location: location)
    }
}

// MARK: - Next Prayer Hero

struct NextPrayerHeroCard: View {
    let vm: PrayerTimeViewModel
    @Environment(PrayerTrackerViewModel.self) private var trackerVM

    private var nextEntry: PrayerEntry?    { vm.nextPrayerEntry }
    private var activePeriod: Prayer       { vm.currentPrayer ?? vm.nextPrayerEntry?.prayer ?? .dhuhr }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: activePeriod.gradient,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(alignment: .leading, spacing: 12) {
                    Text("NEXT PRAYER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .tracking(2)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(nextEntry?.label ?? "--")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        Text(nextEntry?.time ?? "")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(vm.countdownText)
                            .font(.system(size: 48, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white)
                        Text("left")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    if activePeriod.isPrayer {
                        IPrayedButton(prayer: activePeriod, date: Date())
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stats Column

struct QuickStatsColumn: View {
    let entries: [PrayerEntry]
    @Environment(PrayerTrackerViewModel.self) private var trackerVM

    private var sunriseTime: String {
        entries.first(where: { $0.prayer == .sunrise })?.time ?? "--:--"
    }
    private var maghribTime: String {
        entries.first(where: { $0.prayer == .maghrib })?.time ?? "--:--"
    }

    var body: some View {
        VStack(spacing: 12) {
            StatCard(icon: "flame.fill",            iconColor: Prayer.sunrise.color,
                     label: "Streak",               value: "\(trackerVM.currentStreak) days")
            StatCard(icon: "checkmark.circle.fill", iconColor: Prayer.fajr.color,
                     label: "Today",                value: "\(trackerVM.todayCount)/5 prayed")
            StatCard(icon: "sunrise.fill",          iconColor: Prayer.sunrise.color,
                     label: "Sunrise",              value: sunriseTime)
            StatCard(icon: "sunset.fill",           iconColor: Prayer.maghrib.color,
                     label: "Sunset",               value: maghribTime)
        }
        .frame(width: 160)
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(valueColor)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Prayer List Card

struct PrayerListCard: View {
    let entries: [PrayerEntry]
    let trackerRecords: [PrayerRecord]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Prayer Times")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    PrayerListRow(
                        entry: entry,
                        record: trackerRecords.first(where: { $0.prayer == entry.prayer })
                    )
                    if index < entries.count - 1 {
                        Divider().padding(.leading, 52).opacity(0.35)
                    }
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PrayerListRow: View {
    let entry : PrayerEntry
    let record: PrayerRecord?

    @Environment(PrayerTrackerViewModel.self) private var trackerVM
    @State private var showPicker = false

    private var isCurrent: Bool { entry.status == .current }
    private var isSoon:    Bool { entry.status == .soon }
    private var ts: PrayerTrackerStatus? { record?.status }

    var body: some View {
        HStack(spacing: 0) {
            // Col 1: icon
            Image(systemName: entry.prayer.icon)
                .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                .foregroundStyle(iconColor)
                .frame(width: 36, alignment: .center)

            // Col 2: name + pulsing dot
            HStack(spacing: 6) {
                Text(entry.label)
                    .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? entry.prayer.color : entry.isPast ? .secondary : .primary)
                if isCurrent { PulsingDot(color: entry.prayer.color, size: 7) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Col 3: action area
            actionArea
                .frame(width: 110, alignment: .leading)

            // Col 4: time
            Text(entry.time)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(timeColor)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(rowBackground)
    }

    @ViewBuilder
    private var actionArea: some View {
        if isSoon {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill").font(.system(size: 10))
                Text(entry.status.label).font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppColor.softAmber)
        } else if entry.prayer.isPrayer, isCurrent || entry.isPast {
            HStack(spacing: 6) {
                if let ts {
                    HStack(spacing: 4) {
                        Image(systemName: ts.icon).font(.system(size: 10))
                        Text(ts.shortLabel).font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(ts.color)
                }
                Button { showPicker = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                    PrayerStatusPicker(prayer: entry.prayer, date: entry.date ?? Date(), record: record, isCurrent: isCurrent) { newStatus in
                        if let record { trackerVM.mark(record, as: newStatus) }
                        else { trackerVM.create(prayer: entry.prayer, prayerTime: entry.date ?? Date(), status: newStatus) }
                        showPicker = false
                    }
                }
            }
        }
    }

    private var rowBackground: Color {
        if isCurrent { return entry.prayer.color.opacity(0.15) }
        if isSoon    { return AppColor.softAmber.opacity(0.05) }
        return .clear
    }

    private var iconColor: Color {
        if isCurrent { return entry.prayer.color }
        if isSoon    { return AppColor.softAmber }
        if let ts { return ts.color }
        return Color.secondary
    }

    private var timeColor: Color {
        if isCurrent { return entry.prayer.color }
        if isSoon    { return AppColor.softAmber }
        return .secondary
    }
}
