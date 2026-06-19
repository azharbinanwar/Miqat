import SwiftUI

struct MainWindowView: View {
    @State private var selectedItem: SidebarItem = .today
    let settingsVM: SettingsViewModel
    let prayerVM: PrayerTimeViewModel

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selected: $selectedItem)
            Divider()

            VStack(spacing: 0) {
                HeaderBar(vm: settingsVM)
                Divider()

                switch selectedItem {
                case .today:
                    TodayView(vm: settingsVM, prayerVM: prayerVM)
                case .monthly:
                    MonthlyView(prayerVM: prayerVM)
                case .tracker:
                    TrackerView()
                case .stats:
                    StatsView()
                case .notifications:
                    NotificationsView()
                case .location:
                    LocationView()
                case .settings:
                    SettingsView(vm: settingsVM)
                }
            }
        }
        .frame(minWidth: 780, minHeight: 680)
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

    private func placeholderView(_ title: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Header Bar

struct HeaderBar: View {
    let vm: SettingsViewModel

    private var fullDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: Date())
    }

    private var hijriDate: String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hijriDate)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(fullDate)
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()

            HStack(spacing: 0) {
                madhhabButton("Hanafi",  selected: vm.settings.madhab == .hanafi) { vm.update { $0.madhab = .hanafi } }
                madhhabButton("Shafi'i", selected: vm.settings.madhab == .shafi)  { vm.update { $0.madhab = .shafi  } }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func madhhabButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(selected ? AppColor.accentTeal : Color.clear,
                            in: RoundedRectangle(cornerRadius: 7))
                .animation(.spring(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainWindowView(settingsVM: SettingsViewModel(), prayerVM: PrayerTimeViewModel())
        .preferredColorScheme(.dark)
}
