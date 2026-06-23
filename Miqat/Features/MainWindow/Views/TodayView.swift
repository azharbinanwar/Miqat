import SwiftUI

struct TodayView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(PrayerTimeViewModel.self) private var prayerVM

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Top row: next prayer card + quick stats
                    HStack(alignment: .top, spacing: 16) {
                        NextPrayerHeroCard(vm: prayerVM)
                        QuickStatsColumn(entries: prayerVM.entries)
                    }
                    .padding(.horizontal, 24)

                    // Prayer times list
                    PrayerListCard(entries: prayerVM.entries)
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
    @State private var prayed = false

    private var nextEntry: PrayerEntry? { vm.nextPrayerEntry }
    private var activePeriod: Prayer { vm.currentPrayer ?? vm.nextPrayerEntry?.prayer ?? .dhuhr }
    private var gradientColor: Color { activePeriod.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: activePeriod.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

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

                    Button {
                        withAnimation(.spring(duration: 0.25)) { prayed.toggle() }
                    } label: {
                        Label(prayed ? "Prayed ✓" : "I Prayed", systemImage: prayed ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(prayed ? gradientColor : .white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(prayed ? .white : .white.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
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

    private var sunriseTime: String {
        entries.first(where: { $0.prayer == .sunrise })?.time ?? "--:--"
    }
    private var maghribTime: String {
        entries.first(where: { $0.prayer == .maghrib })?.time ?? "--:--"
    }

    var body: some View {
        VStack(spacing: 12) {
            StatCard(icon: "flame.fill",           iconColor: Prayer.sunrise.color,
                     label: "Streak",              value: "-- days")
            StatCard(icon: "checkmark.circle.fill", iconColor: Prayer.fajr.color,
                     label: "Today",               value: "--/5 prayed")
            StatCard(icon: "sunrise.fill",         iconColor: Prayer.sunrise.color,
                     label: "Sunrise",             value: sunriseTime)
            StatCard(icon: "sunset.fill",          iconColor: Prayer.maghrib.color,
                     label: "Sunset",              value: maghribTime)
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
                    PrayerListRow(entry: entry)
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
    let entry: PrayerEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.prayer.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(entry.prayer.color.opacity(entry.status == .prayed || entry.status == .passed ? 0.35 : 1))
                .frame(width: 22)

            Text(entry.label)
                .font(.system(size: 14, weight: entry.isCurrent ? .semibold : .regular))
                .foregroundStyle(entry.isCurrent ? .primary : entry.status == .prayed || entry.status == .passed ? .secondary : .primary)

            Spacer()

            Text(entry.time)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(entry.isAlert ? AppColor.alert : entry.isCurrent ? entry.prayer.color : .secondary)

            statusView
                .frame(width: 82, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        // flat colour — no corner radius — clipShape on card handles edges
        .background(
            entry.isCurrent ? entry.prayer.color.opacity(0.09) :
            entry.isAlert   ? AppColor.alert.opacity(0.05) : Color.clear
        )
    }

    @ViewBuilder
    private var statusView: some View {
        switch entry.status {
        case .prayed:
            Label("Prayed", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(entry.prayer.color)
        case .passed:
            Label("Passed", systemImage: "checkmark.circle")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .current:
            Text("Now")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(entry.prayer.color, in: Capsule())
        case .upcoming:
            Text("Upcoming")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        case .alert:
            Label("Soon", systemImage: "bell.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColor.alert)
        }
    }
}
