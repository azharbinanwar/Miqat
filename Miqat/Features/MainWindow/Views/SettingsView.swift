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
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.system(size: 13, weight: .medium))

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

// Generic ± stepper row for prayer time offset
struct AdjustmentRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var value: Int
    var range: ClosedRange<Int> = -30...30
    var step: Int     = 1
    var unit: String  = "min"
    var showSign: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            Text(label)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound { value -= step }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(value > range.lowerBound ? .primary : .tertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                Text(displayValue)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .frame(width: 36, alignment: .center)

                Button {
                    if value + step <= range.upperBound { value += step }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(value < range.upperBound ? .primary : .tertiary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))

            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }

    private var displayValue: String {
        if !showSign { return "\(value)" }
        if value == 0 { return "0" }
        return value > 0 ? "+\(value)" : "\(value)"
    }

    private var valueColor: Color {
        if !showSign { return Color(hex: "#0D9488") }
        if value == 0 { return .secondary }
        return value > 0 ? Color(hex: "#0D9488") : Color(hex: "#DC2626")
    }
}

// MARK: - Settings Enums

enum MenuBarDisplay: String, CaseIterable { case countdown = "Countdown"; case nextTime = "Next Time" }
enum AppTheme: String, CaseIterable { case light = "Light"; case dark = "Dark"; case system = "System" }
// Madhab is defined globally in MockPrayerData.swift
enum CalcMethod: String, CaseIterable {
    case mwl     = "MWL"
    case isna    = "ISNA"
    case egypt   = "Egypt"
    case makkah  = "Makkah"
    case karachi = "Karachi"
}
enum HighLatRule: String, CaseIterable {
    case middleNight = "Middle Night"
    case seventhNight = "1/7 Night"
    case angleBased  = "Angle"
}

// MARK: - Settings View

struct SettingsView: View {
    // Location
    @State private var locationCity    = "London, UK"

    // Prayer calculation
    @State private var calcMethod: CalcMethod      = .mwl
    @State private var madhab: Madhab               = .hanafi
    @State private var highLatRule: HighLatRule     = .middleNight

    // Time adjustments (minutes offset per prayer)
    @State private var fajrAdj    = 0
    @State private var shuruqAdj  = 0
    @State private var dhuhrAdj   = 0
    @State private var asrAdj     = 0
    @State private var maghribAdj = 0
    @State private var ishaAdj    = 0
    @State private var hijriAdj   = 0

    // Menu bar
    @State private var menuShowPrayerName   = true
    @State private var menuShowIcon         = true
    @State private var menuDisplay: MenuBarDisplay = .countdown
    @State private var orangeThreshold      = 30
    @State private var redThreshold         = 20

    // Appearance
    @State private var theme: AppTheme              = .system
    @State private var accentIndex: Int             = 0

    // Startup
    @State private var launchAtLogin               = true
    @State private var showWidgetOnLaunch          = true
    @State private var openWindowOnLaunch          = false

    private let accentColors: [(String, Color)] = [
        ("Teal",   Color(hex: "#0D9488")),
        ("Purple", Color(hex: "#7C3AED")),
        ("Gold",   Color(hex: "#D97706")),
        ("Blue",   Color(hex: "#2563EB")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    locationCard
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

    // MARK: Location card
    private var locationCard: some View {
        settingsCard(title: "Location", icon: "location.fill", iconColor: Color(hex: "#2563EB")) {
            HStack(spacing: 14) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#2563EB"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#2563EB").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(locationCity)
                        .font(.system(size: 13, weight: .medium))
                    Text("51.5074° N, 0.1278° W")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button { } label: {
                    Label("Auto-detect", systemImage: "location.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#2563EB"))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2563EB").opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#2563EB").opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsActionRow(
                icon: "magnifyingglass",
                iconColor: Color(hex: "#2563EB"),
                title: "Search location",
                subtitle: "Enter a city or coordinates manually"
            )
        }
    }

    // MARK: Calculation card
    private var calculationCard: some View {
        settingsCard(title: "Prayer Calculation", icon: "moon.stars.fill", iconColor: Color(hex: "#7C3AED")) {
            // Calc method picker (horizontal scroll)
            HStack(spacing: 14) {
                Image(systemName: "function")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#7C3AED"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#7C3AED").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                Text("Method")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                HStack(spacing: 0) {
                    ForEach(CalcMethod.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.spring(duration: 0.18)) { calcMethod = m }
                        } label: {
                            Text(m.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(calcMethod == m ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    calcMethod == m ? Color(hex: "#7C3AED") : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsSegmentRow(
                icon: "person.fill",
                iconColor: Color(hex: "#0D9488"),
                title: "Madhab",
                selection: $madhab
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsSegmentRow(
                icon: "globe",
                iconColor: Color(hex: "#7C3AED"),
                title: "High Latitude",
                selection: $highLatRule
            )

            // Manual adjustments section
            Divider().padding(.horizontal, 16).opacity(0.4)

            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#7C3AED"))
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

            AdjustmentRow(label: "Fajr",    icon: "moon.stars.fill", iconColor: Color(hex: "#7C3AED"), value: $fajrAdj)
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Shuruq",  icon: "sunrise.fill",    iconColor: Color(hex: "#F59E0B"), value: $shuruqAdj)
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Dhuhr",   icon: "sun.max.fill",    iconColor: Color(hex: "#0D9488"), value: $dhuhrAdj)
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Asr",     icon: "sun.min.fill",    iconColor: Color(hex: "#D97706"), value: $asrAdj)
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Maghrib", icon: "sunset.fill",     iconColor: Color(hex: "#DC2626"), value: $maghribAdj)
            Divider().padding(.leading, 58).opacity(0.25)
            AdjustmentRow(label: "Isha",    icon: "moon.fill",       iconColor: Color(hex: "#4F46E5"), value: $ishaAdj)

            Divider().padding(.horizontal, 16).opacity(0.4)

            AdjustmentRow(label: "Hijri date", icon: "calendar",     iconColor: Color(hex: "#0D9488"),
                          value: $hijriAdj, range: -3...3)
                .padding(.bottom, 2)
        }
    }

    // MARK: Menu Bar card
    private var menuBarCard: some View {
        settingsCard(title: "Menu Bar", icon: "menubar.rectangle", iconColor: Color(hex: "#0D9488")) {

            // What to show in title
            SettingsSegmentRow(
                icon: "timer",
                iconColor: Color(hex: "#0D9488"),
                title: "Display",
                selection: $menuDisplay
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "textformat",
                iconColor: Color(hex: "#0D9488"),
                title: "Show prayer name",
                subtitle: "e.g.  Asr  42:18",
                isOn: $menuShowPrayerName
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "app.fill",
                iconColor: Color(hex: "#0D9488"),
                title: "Show app icon",
                subtitle: "Moon icon next to the text",
                isOn: $menuShowIcon
            )

            Divider().padding(.horizontal, 16).opacity(0.4)

            // Preview bar
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    if menuShowIcon {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    if menuShowPrayerName {
                        Text(menuDisplay == .countdown ? "Asr  42:18" : "Asr  4:42 PM")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                    } else {
                        Text(menuDisplay == .countdown ? "42:18" : "4:42 PM")
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

            Divider().padding(.horizontal, 16).opacity(0.4)

            // Warning colour thresholds
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#F59E0B"))
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
                iconColor: Color(hex: "#F59E0B"),
                value: $orangeThreshold,
                range: 10...60,
                step: 5,
                showSign: false
            )

            Divider().padding(.leading, 58).opacity(0.25)

            AdjustmentRow(
                label: "Red alert",
                icon: "circle.fill",
                iconColor: Color(hex: "#DC2626"),
                value: $redThreshold,
                range: 5...30,
                step: 5,
                showSign: false
            )
            .padding(.bottom, 2)
        }
    }

    // MARK: Appearance card
    private var appearanceCard: some View {
        settingsCard(title: "Appearance", icon: "paintbrush.fill", iconColor: Color(hex: "#F59E0B")) {
            SettingsSegmentRow(
                icon: "circle.lefthalf.filled",
                iconColor: Color(hex: "#F59E0B"),
                title: "Theme",
                selection: $theme
            )

            Divider().padding(.leading, 58).opacity(0.3)

            // Accent colour picker
            HStack(spacing: 14) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#F59E0B"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#F59E0B").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                Text("Accent colour")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                HStack(spacing: 8) {
                    ForEach(Array(accentColors.enumerated()), id: \.offset) { index, pair in
                        Button {
                            withAnimation(.spring(duration: 0.18)) { accentIndex = index }
                        } label: {
                            ZStack {
                                Circle().fill(pair.1).frame(width: 22, height: 22)
                                if accentIndex == index {
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
        settingsCard(title: "Startup", icon: "power", iconColor: Color(hex: "#0D9488")) {
            SettingsToggleRow(
                icon: "power",
                iconColor: Color(hex: "#0D9488"),
                title: "Launch at login",
                subtitle: "Start Miqat automatically when you log in",
                isOn: $launchAtLogin
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "macwindow",
                iconColor: Color(hex: "#0D9488"),
                title: "Show widget on launch",
                subtitle: "Floating prayer times panel on desktop",
                isOn: $showWidgetOnLaunch
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsToggleRow(
                icon: "rectangle.stack.fill",
                iconColor: Color(hex: "#0D9488"),
                title: "Open main window on launch",
                subtitle: "Show full app window at startup",
                isOn: $openWindowOnLaunch
            )
        }
    }

    // MARK: About card
    private var aboutCard: some View {
        settingsCard(title: "About", icon: "info.circle.fill", iconColor: .secondary) {
            HStack(spacing: 14) {
                Image(systemName: "app.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#0D9488"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#0D9488").opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

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
                    .foregroundStyle(Color(hex: "#0D9488"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsActionRow(
                icon: "star.fill",
                iconColor: Color(hex: "#F59E0B"),
                title: "Rate on App Store",
                subtitle: "Enjoying Miqat? Leave a review"
            )

            Divider().padding(.leading, 58).opacity(0.3)

            SettingsActionRow(
                icon: "envelope.fill",
                iconColor: Color(hex: "#2563EB"),
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
}
