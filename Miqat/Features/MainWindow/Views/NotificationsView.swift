import SwiftUI

// MARK: - Data

struct PrayerNotifConfig: Identifiable {
    let id = UUID()
    let referenceTime: ReferenceTime
    var enabled: Bool
    var xMinutes: Int        // 20–60, reminder before prayer
    var atPrayerTime: Bool   // alert at exact start
    var zEnabled: Bool       // jamaat reminder toggle
    var zMinutes: Int        // 5–60, after prayer start
    var sound: AppSound
    var customSoundURL: URL?

    var soundDisplayName: String {
        sound == .custom ? (customSoundURL?.lastPathComponent ?? "Custom") : sound.displayName
    }
}

// MARK: - Generic Tiles

// One generic accordion row per prayer
struct NotifPrayerRow: View {
    @Binding var config: PrayerNotifConfig
    @State private var showSoundPicker = false

    var body: some View {
        NotifAccordionRow(
            icon: config.referenceTime.icon,
            iconColor: config.referenceTime.color,
            title: config.referenceTime.rawValue,
            subtitle: summaryText,
            enabled: $config.enabled
        ) {
            AdjustmentRow(
                label: "Remind me before",
                icon: "bell.fill",
                iconColor: config.referenceTime.color,
                value: $config.xMinutes,
                range: 20...60, step: 5, unit: "min", showSign: false
            )

            Divider().padding(.horizontal, 32).opacity(0.25)

            NotifToggleRow(
                icon: "bell.badge.fill",
                iconColor: config.referenceTime.color,
                label: "Alert at prayer time",
                isOn: $config.atPrayerTime
            )

            Divider().padding(.horizontal, 32).opacity(0.25)

            NotifToggleRow(
                icon: "figure.walk",
                iconColor: AppColor.accentGold,
                label: "Jamaat reminder",
                isOn: $config.zEnabled
            )

            if config.zEnabled {
                AdjustmentRow(
                    label: "After prayer starts",
                    icon: "clock.badge.fill",
                    iconColor: AppColor.accentGold,
                    value: $config.zMinutes,
                    range: 5...60, step: 5, unit: "min", showSign: false
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().padding(.horizontal, 32).opacity(0.25)

            SettingsDetailRow(
                icon: "speaker.wave.2.fill",
                iconColor: config.referenceTime.color,
                title: "Sound",
                value: config.soundDisplayName
            ) { showSoundPicker = true }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerDialog(current: config.sound) { sound, url in
                    config.sound = sound
                    config.customSoundURL = url
                }
            }
        }
        .animation(.spring(duration: 0.18), value: config.zEnabled)
    }

    private var summaryText: String {
        var parts: [String] = ["\(config.xMinutes)m early"]
        if config.atPrayerTime { parts.append("at prayer") }
        if config.zEnabled { parts.append("jamaat +\(config.zMinutes)m") }
        parts.append(config.soundDisplayName)
        return parts.joined(separator: " · ")
    }
}

// Friday Jumu'ah row — uses same NotifAccordionRow generic component
struct FridayJumuahRow: View {
    @Binding var config: FridayJumuahConfig
    @State private var showSoundPicker = false

    var body: some View {
        NotifAccordionRow(
            icon: "building.columns.fill",
            iconColor: AppColor.accentGold,
            title: "Jumu'ah",
            subtitle: summaryText,
            enabled: $config.enabled
        ) {
            AdjustmentRow(
                label: "Remind me before",
                icon: "bell.fill",
                iconColor: AppColor.accentGold,
                value: $config.xMinutes,
                range: 5...60, step: 5, unit: "min", showSign: false
            )

            Divider().padding(.horizontal, 32).opacity(0.25)

            AdjustmentRow(
                label: "Khutbah / jamaat after",
                icon: "figure.stand",
                iconColor: AppColor.accentGold,
                value: $config.zMinutes,
                range: 5...60, step: 5, unit: "min", showSign: false
            )

            Divider().padding(.horizontal, 32).opacity(0.25)

            NotifToggleRow(
                icon: "clock.arrow.circlepath",
                iconColor: AppColor.accentGold,
                label: "Remind if missed",
                isOn: $config.missedEnabled
            )

            if config.missedEnabled {
                AdjustmentRow(
                    label: "Remind after prayer time",
                    icon: "bell.badge.slash",
                    iconColor: AppColor.alert,
                    value: $config.missedMinutes,
                    range: 5...120, step: 5, unit: "min", showSign: false
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().padding(.horizontal, 32).opacity(0.25)

            SettingsDetailRow(
                icon: "speaker.wave.2.fill",
                iconColor: AppColor.accentGold,
                title: "Sound",
                value: config.sound.displayName
            ) { showSoundPicker = true }
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerDialog(current: config.sound) { sound, _ in
                    config.sound = sound
                }
            }
        }
        .animation(.spring(duration: 0.18), value: config.missedEnabled)
    }

    private var summaryText: String {
        var parts = ["\(config.xMinutes)m early", "jamaat +\(config.zMinutes)m"]
        if config.missedEnabled { parts.append("missed →\(config.missedMinutes)m") }
        return parts.joined(separator: " · ")
    }
}

// Per-anchor row for Surah Kahf: toggle + optional stepper + optional time picker
struct KahfAnchorRow: View {
    @Binding var config: KahfAnchorConfig
    @State private var showSoundPicker = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: config.anchor.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(config.enabled ? config.anchor.color : .secondary.opacity(0.35))
                    .frame(width: 28, height: 28)
                    .background(
                        (config.enabled ? config.anchor.color : Color.secondary).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 7)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.anchor.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(config.enabled ? .primary : .secondary)
                    Text(config.anchor.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $config.enabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(config.anchor.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if config.enabled {
                Divider().padding(.leading, 60).opacity(0.2)

                if config.anchor.hasOffset {
                    AdjustmentRow(
                        label: "After",
                        icon: "clock",
                        iconColor: config.anchor.color,
                        value: $config.minutesAfter,
                        range: 5...120,
                        step: 5,
                        unit: "min",
                        showSign: false
                    )
                } else {
                    // Custom time picker for .customTime
                    HStack(spacing: 14) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(config.anchor.color)
                            .frame(width: 28, height: 28)
                            .background(config.anchor.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                        Text("Time")
                            .font(.system(size: 13, weight: .medium))

                        Spacer()

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { config.fixedTime ?? Date() },
                                set: { config.fixedTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .frame(width: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                }
            }
        }
        .animation(.spring(duration: 0.18), value: config.enabled)
    }
}

// One generic toggle row for general settings
struct NotifToggleRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(iconColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Notifications View

struct NotificationsView: View {
    @State private var configs: [PrayerNotifConfig] = [
        PrayerNotifConfig(referenceTime: .fajr,    enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
        PrayerNotifConfig(referenceTime: .dhuhr,   enabled: true, xMinutes: 20, atPrayerTime: false, zEnabled: true, zMinutes: 30, sound: .systemDefault),
        PrayerNotifConfig(referenceTime: .asr,     enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
        PrayerNotifConfig(referenceTime: .maghrib, enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 10, sound: .systemDefault),
        PrayerNotifConfig(referenceTime: .isha,    enabled: true, xMinutes: 20, atPrayerTime: true,  zEnabled: true, zMinutes: 15, sound: .systemDefault),
    ]

    @State private var allEnabled        = true
    @State private var iPrayedAction     = true
    @State private var snoozeEnabled     = true
    @State private var respectDND        = true
    @State private var testSent          = false
    @State private var selectedTestPrayer: Int = 0
    @State private var mulkConfig        = SurahMulkConfig()
    @State private var kahfConfig        = SurahKahfConfig()
    @State private var jumuahConfig      = FridayJumuahConfig()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    prayerAlertsCard
                    actionsCard
                    generalCard
                    surahMulkCard
                    surahKahfCard
                    testNotificationCard
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
                Text("Notifications")
                    .font(.system(size: 16, weight: .bold))
                Text("Customise alerts per prayer")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Text("All Alerts")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Toggle("", isOn: $allEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(AppColor.accentTeal)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: Prayer alerts card
    private var prayerAlertsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Prayer Alerts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(configs.filter(\.enabled).count)/\(configs.count) on")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            VStack(spacing: 0) {
                ForEach($configs) { $config in
                    NotifPrayerRow(config: $config)
                        .disabled(!allEnabled)
                        .opacity(allEnabled ? 1 : 0.45)
                    Divider().padding(.leading, 52).opacity(0.3)
                }

                // Friday Jumu'ah — separate config inside same card
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AppColor.accentGold.opacity(0.7))
                    Text("FRIDAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColor.accentGold.opacity(0.7))
                        .kerning(1)
                    Rectangle()
                        .fill(AppColor.accentGold.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                FridayJumuahRow(config: $jumuahConfig)
                    .disabled(!allEnabled)
                    .opacity(allEnabled ? 1 : 0.45)
            }
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: General card
    private var generalCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("System")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            NotifToggleRow(
                icon: "moon.fill",
                iconColor: Color(hex: "#6366F1"),
                label: "Respect Focus / DND",
                subtitle: "Silence during macOS Focus modes",
                isOn: $respectDND
            )

            Divider().padding(.leading, 52).opacity(0.3)

            NotifToggleRow(
                icon: "bell.badge.slash.fill",
                iconColor: AppColor.accentGold,
                label: "Fajr Exception",
                subtitle: "Always alert for Fajr even in DND",
                isOn: .constant(true)
            )
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Test notification card
    private var testNotificationCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test Notification")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Push a sample alert to see how it looks")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16).opacity(0.4)

            HStack(spacing: 12) {
                // Prayer picker
                HStack(spacing: 0) {
                    ForEach(Array(configs.enumerated()), id: \.element.id) { index, config in
                        Button {
                            withAnimation(.spring(duration: 0.15)) { selectedTestPrayer = index }
                        } label: {
                            Image(systemName: config.referenceTime.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(selectedTestPrayer == index ? .white : config.referenceTime.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    selectedTestPrayer == index ? config.referenceTime.color : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08), lineWidth: 1))

                Spacer()

                // Send test button
                Button {
                    withAnimation(.spring(duration: 0.2)) { testSent = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { testSent = false }
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: testSent ? "checkmark.circle.fill" : "bell.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(testSent ? "Sent!" : "Send Test")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        testSent ? AppColor.accentTeal : configs[selectedTestPrayer].referenceTime.color,
                        in: RoundedRectangle(cornerRadius: 9)
                    )
                }
                .buttonStyle(.plain)
                .disabled(testSent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Surah Mulk card
    private var surahMulkCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(ReferenceTime.isha.color)
                    .frame(width: 28, height: 28)
                    .background(ReferenceTime.isha.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Surah Mulk")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Daily reminder after Isha")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $mulkConfig.enabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(ReferenceTime.isha.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if mulkConfig.enabled {
                Divider().padding(.horizontal, 16).opacity(0.3)

                AdjustmentRow(
                    label: "After Isha",
                    icon: "moon.fill",
                    iconColor: ReferenceTime.isha.color,
                    value: $mulkConfig.minutesAfterIsha,
                    range: 5...120,
                    step: 5,
                    unit: "min",
                    showSign: false
                )
                .transition(.opacity.combined(with: .move(edge: .top)))

                Divider().padding(.horizontal, 32).opacity(0.25)

                mulkSoundRow
            }
        }
        .animation(.spring(duration: 0.22), value: mulkConfig.enabled)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    @State private var showMulkSoundPicker = false
    private var mulkSoundRow: some View {
        SettingsDetailRow(
            icon: "speaker.wave.2.fill",
            iconColor: ReferenceTime.isha.color,
            title: "Sound",
            value: mulkConfig.sound.displayName
        ) { showMulkSoundPicker = true }
        .sheet(isPresented: $showMulkSoundPicker) {
            SoundPickerDialog(current: mulkConfig.sound) { sound, _ in
                mulkConfig.sound = sound
            }
        }
    }

    // MARK: Surah Kahf card
    private var surahKahfCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Surah Kahf")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Thu – Fri")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            ForEach($kahfConfig.anchors) { $anchor in
                KahfAnchorRow(config: $anchor)
                if anchor.id != kahfConfig.anchors.last?.id {
                    Divider().padding(.leading, 60).opacity(0.3)
                }
            }
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Actions card
    private var actionsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Actions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Divider().padding(.horizontal, 16).opacity(0.4)

            NotifToggleRow(
                icon: "hand.thumbsup.fill",
                iconColor: AppColor.accentTeal,
                label: "\"I Prayed\" Quick Action",
                subtitle: "Mark prayer from the notification banner",
                isOn: $iPrayedAction
            )

            Divider().padding(.leading, 52).opacity(0.3)

            NotifToggleRow(
                icon: "clock.arrow.circlepath",
                iconColor: AppColor.accentGold,
                label: "Snooze (5 min)",
                subtitle: "Remind again if dismissed without marking",
                isOn: $snoozeEnabled
            )
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
