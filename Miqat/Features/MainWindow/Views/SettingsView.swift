import SwiftUI

// MARK: - Generic Tiles

// Generic toggle row (reusable across all sections)
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(iconColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

// Generic nav/action row (chevron or button on right)
struct SettingsActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var value: String = ""
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Generic segment picker row
struct SettingsSegmentRow<T: RawRepresentable & CaseIterable & Hashable>: View
where T.RawValue == String, T.AllCases: RandomAccessCollection {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String = ""
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.spring(duration: 0.18)) { selection = option }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(selection == option ? .white : .secondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                selection == option ? iconColor : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(SettingsViewModel.self)  private var vm
    @Environment(ThemeViewModel.self)     private var themeVM
    @Environment(PrayerTimeViewModel.self) private var previewVM

    // Prayer calculation — read from global VM
    @State private var showMethodDialog = false

    // Time adjustments — read from global VM

    // Menu bar, appearance, startup — all read from global VM

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    calendarCard
                    calculationCard
                    menuBarCard
                    appearanceCard
                    startupCard
                    aboutCard
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { loadPreview() }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in loadPreview() }
        .sheet(isPresented: $showMethodDialog) {
            MethodPickerDialog(selection: vm.binding(for: \.calculationMethod)) { _ in }
        }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 16, weight: .bold))
                Text("Preferences & configuration")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: Calculation card
    private var calculationCard: some View {
        settingsCard(title: "Prayer Calculation", icon: "moon.stars.fill", iconColor: AppColor.accentPurple) {
            SettingsActionRow(
                icon: "function",
                iconColor: AppColor.accentPurple,
                title: "Method",
                subtitle: "Calculation method for prayer times",
                value: vm.settings.calculationMethod.displayName
            ) {
                showMethodDialog = true
            }

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsSegmentRow(
                icon: "person.fill",
                iconColor: AppColor.accentTeal,
                title: "Madhab",
                subtitle: "Affects Asr prayer time",
                selection: vm.binding(for: \.madhab)
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsSegmentRow(
                icon: "globe",
                iconColor: AppColor.accentPurple,
                title: "High Latitude",
                subtitle: "For regions near the poles",
                selection: vm.binding(for: \.highLatRule)
            )

            // Manual adjustments section
            Divider().padding(.horizontal, 16).opacity(0.4)

            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.accentPurple)
                Text("Manual Time Adjustments")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("fine-tune each prayer ± minutes")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 2)

            AdjustmentRow(label: "Fajr",    icon: Prayer.fajr.icon,     iconColor: Prayer.fajr.color,    value: vm.binding(for: \.fajrAdjustment))
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: Prayer.sunrise.label, icon: Prayer.sunrise.icon, iconColor: Prayer.sunrise.color, value: vm.binding(for: \.sunriseAdjustment))
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Dhuhr",   icon: Prayer.dhuhr.icon,    iconColor: Prayer.dhuhr.color,   value: vm.binding(for: \.dhuhrAdjustment))
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Asr",     icon: Prayer.asr.icon,      iconColor: Prayer.asr.color,     value: vm.binding(for: \.asrAdjustment))
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Maghrib", icon: Prayer.maghrib.icon,  iconColor: Prayer.maghrib.color, value: vm.binding(for: \.maghribAdjustment))
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Isha",    icon: Prayer.isha.icon,     iconColor: Prayer.isha.color,    value: vm.binding(for: \.ishaAdjustment))

        }
    }

    // MARK: Calendar card

    private var calendarCard: some View {
        settingsCard(title: "Calendar", icon: "calendar", iconColor: AppColor.accentTeal) {
            AdjustmentRow(
                label: "Date Adjustment",
                subtitle: "For local moon sighting",
                icon: "moon.stars",
                iconColor: AppColor.accentTeal,
                value: vm.binding(for: \.hijriAdjustment),
                range: -2...2
            )
            .padding(.bottom, 2)
        }
    }

    // MARK: Menu Bar card
    private var menuBarCard: some View {
        settingsCard(title: "Menu Bar", icon: "menubar.rectangle", iconColor: AppColor.accentTeal) {

            // What to show in title
            SettingsSegmentRow(
                icon: "timer",
                iconColor: AppColor.accentTeal,
                title: "Display",
                subtitle: "What shows in the menu bar",
                selection: vm.binding(for: \.menuDisplay)
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "textformat",
                iconColor: AppColor.accentTeal,
                title: "Show prayer name",
                subtitle: "e.g.  Asr  42:18",
                isOn: vm.binding(for: \.menuShowPrayerName)
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "app.fill",
                iconColor: AppColor.accentTeal,
                title: "Show app icon",
                subtitle: "Moon icon next to the text",
                isOn: vm.binding(for: \.menuShowIcon)
            )

            SettingsToggleRow(
                icon: "number",
                iconColor: AppColor.accentTeal,
                title: "Show seconds",
                subtitle: "42:18 vs 42:18:00 in countdown",
                isOn: vm.binding(for: \.menuShowSeconds)
            )

            Divider().padding(.horizontal, 16).opacity(0.4)

            // Preview bar
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    if vm.settings.menuShowIcon {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    if vm.settings.menuShowPrayerName {
                        Text(vm.settings.menuDisplay == .countdown ? previewCountdownText : previewTimeText)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    } else {
                        Text(vm.settings.menuDisplay == .countdown ? previewCountdownOnly : previewTimeOnly)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                Spacer()
            }
            .padding(.vertical, 12)

            // Warning colour thresholds
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.accentGold)
                Text("Colour Warnings")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("applies to countdown only")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 2)

            AdjustmentRow(
                label: "Orange alert",
                icon: "circle.fill",
                iconColor: AppColor.accentGold,
                value: vm.binding(for: \.orangeThreshold),
                range: 10...60,
                step: 5,
                showSign: false
            )

            Divider().padding(.leading, 58).opacity(0.25)

            AdjustmentRow(
                label: "Red alert",
                icon: "circle.fill",
                iconColor: AppColor.alert,
                value: vm.binding(for: \.redThreshold),
                range: 5...30,
                step: 5,
                showSign: false
            )
            .padding(.bottom, 2)
        }
    }

    // MARK: Appearance card
    private var appearanceCard: some View {
        settingsCard(title: "Appearance", icon: "paintbrush.fill", iconColor: AppColor.accentGold) {
            ThemePickerRow(selection: themeVM.binding(for: \.appTheme), accentColor: themeVM.accentColor)

            Divider().padding(.leading, 58).opacity(0.3)

            // Accent colour picker
            HStack(spacing: 14) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.accentGold)
                    .frame(width: 28, height: 28)
                    .background(AppColor.accentGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                Text("Accent colour")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                HStack(spacing: 8) {
                    ForEach(Array(AppColor.accentOptions.enumerated()), id: \.offset) { index, pair in
                        Button {
                            withAnimation(.spring(duration: 0.18)) {
                                themeVM.update { $0.accentColorIndex = index }
                            }
                        } label: {
                            ZStack {
                                Circle().fill(pair.1).frame(width: 22, height: 22)
                                if themeVM.settings.accentColorIndex == index {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
    }

    // MARK: Startup card
    private var startupCard: some View {
        settingsCard(title: "Startup", icon: "power", iconColor: AppColor.accentTeal) {
            SettingsToggleRow(
                icon: "power",
                iconColor: AppColor.accentTeal,
                title: "Launch at login",
                subtitle: "Start Miqat automatically when you log in",
                isOn: vm.binding(for: \.launchAtLogin)
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "menubar.rectangle",
                iconColor: AppColor.accentTeal,
                title: "Open main window on launch",
                subtitle: "Show full app window at startup",
                isOn: vm.binding(for: \.openWindowOnLaunch)
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsSegmentRow(
                icon: "macwindow",
                iconColor: AppColor.accentTeal,
                title: "Floating panel",
                subtitle: "Off — hidden, Normal — this Space, Always — all Spaces above all apps",
                selection: vm.binding(for: \.floatingPanelMode)
            )

            if vm.settings.floatingPanelMode != .off {
                Divider().padding(.leading, 58).opacity(0.3)
                FloatingPanelSizePicker(selection: vm.binding(for: \.floatingPanelSize))
            }
        }
    }

    // MARK: About card
    private var aboutCard: some View {
        settingsCard(title: "About", icon: "info.circle.fill", iconColor: .secondary) {
            HStack(spacing: 14) {
                Image(systemName: "app.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.accentTeal)
                    .frame(width: 28, height: 28)
                    .background(AppColor.accentTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Miqat")
                        .font(.system(size: 13, weight: .medium))
                    Text("Version 1.0.0 (1)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Up to date")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColor.accentTeal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsActionRow(
                icon: "star.fill",
                iconColor: AppColor.accentGold,
                title: "Rate on App Store",
                subtitle: "Enjoying Miqat? Leave a review"
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsActionRow(
                icon: "envelope.fill",
                iconColor: AppColor.accentBlue,
                title: "Send feedback",
                subtitle: "Report a bug or suggest a feature"
            )
        }
    }

    // MARK: Card container helper
    private func settingsCard(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            content()

            Spacer().frame(height: 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Preview helpers
    private func loadPreview() {
        let repo = ServiceLocator.shared.resolve(LocationRepository.self)
        let location = repo.getActiveLocation() ?? Location.presets[0]
        previewVM.update(settings: vm.settings.prayerCalculationSettings)
        previewVM.load(location: location)
    }

    private var previewPrayerName: String { previewVM.nextPrayerEntry?.prayer.rawValue ?? "--" }
    private var previewTimeText: String   { previewPrayerName + "  " + (previewVM.nextPrayerEntry?.time ?? "--:--") }
    private var previewTimeOnly: String   { previewVM.nextPrayerEntry?.time ?? "--:--" }
    private var previewCountdownText: String {
        previewPrayerName + "  " + (vm.settings.menuShowSeconds ? previewVM.countdownText : stripSeconds(previewVM.countdownText))
    }
    private var previewCountdownOnly: String {
        vm.settings.menuShowSeconds ? previewVM.countdownText : stripSeconds(previewVM.countdownText)
    }
    private func stripSeconds(_ s: String) -> String {
        let p = s.split(separator: ":")
        if p.count == 3 { return "\(p[0]):\(p[1])" }
        if p.count == 2 { return String(p[0]) }
        return s
    }
}

// MARK: - Floating Panel Size Picker

private struct FloatingPanelSizePicker: View {
    @Binding var selection: FloatingPanelSize

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FloatingPanelSize.allCases, id: \.self) { size in
                Button { selection = size } label: {
                    VStack(spacing: 8) {
                        miniCard(for: size)
                        Text(size.rawValue)
                            .font(.system(size: 11, weight: selection == size ? .semibold : .regular))
                            .foregroundStyle(selection == size ? AppColor.accentTeal : .secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 130)
                    .padding(.vertical, 10)
                    .background(
                        selection == size ? AppColor.accentTeal.opacity(0.07) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func miniCard(for size: FloatingPanelSize) -> some View {
        let selected = selection == size
        let ink: Color = selected ? AppColor.accentTeal : .secondary
        let w: CGFloat = 58
        let h: CGFloat = size == .small ? 22 : size == .medium ? 74 : 90

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 5)
                .fill(selected ? AppColor.accentTeal.opacity(0.08) : Color(NSColor.controlBackgroundColor))
            RoundedRectangle(cornerRadius: 5)
                .stroke(selected ? AppColor.accentTeal : Color.secondary.opacity(0.28), lineWidth: selected ? 1.5 : 1)
            switch size {
            case .small:  smallWire(ink: ink)
            case .medium: mediumWire(ink: ink)
            case .large:  largeWire(ink: ink)
            }
        }
        .frame(width: w, height: h)
    }

    private func smallWire(ink: Color) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(ink.opacity(0.7)).frame(width: 22, height: 4)
            Spacer()
            Circle().fill(ink.opacity(0.4)).frame(width: 6)
        }
        .padding(.horizontal, 7)
        .frame(maxHeight: .infinity)
    }

    private func mediumWire(ink: Color) -> some View {
        VStack(spacing: 3) {
            Capsule().fill(ink.opacity(0.4)).frame(width: 20, height: 3)
            Capsule().fill(ink.opacity(0.8)).frame(width: 32, height: 5)
            Capsule().fill(ink.opacity(0.3)).frame(width: 24, height: 3)
            Divider().opacity(0.2).padding(.vertical, 1)
            ForEach(0..<5) { i in prayerWire(ink: ink, current: i == 2) }
        }
        .padding(.top, 7).padding(.bottom, 4)
    }

    private func largeWire(ink: Color) -> some View {
        VStack(spacing: 3) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Capsule().fill(ink.opacity(0.3)).frame(width: 18, height: 2)
                    Capsule().fill(ink.opacity(0.5)).frame(width: 26, height: 3)
                }
                Spacer()
                Circle().fill(ink.opacity(0.25)).frame(width: 8)
            }
            .padding(.horizontal, 5)
            Divider().opacity(0.2)
            Capsule().fill(ink.opacity(0.4)).frame(width: 20, height: 3)
            Capsule().fill(ink.opacity(0.8)).frame(width: 32, height: 5)
            Capsule().fill(ink.opacity(0.3)).frame(width: 24, height: 3)
            Divider().opacity(0.2).padding(.vertical, 1)
            ForEach(0..<5) { i in prayerWire(ink: ink, current: i == 2) }
        }
        .padding(.top, 6).padding(.bottom, 4)
    }

    private func prayerWire(ink: Color, current: Bool) -> some View {
        HStack(spacing: 3) {
            Circle().fill(ink.opacity(current ? 0.8 : 0.4)).frame(width: 4)
            Capsule().fill(ink.opacity(current ? 0.7 : 0.35)).frame(height: 3)
            Capsule().fill(ink.opacity(0.25)).frame(width: 12, height: 3)
        }
        .padding(.horizontal, 5)
    }
}
