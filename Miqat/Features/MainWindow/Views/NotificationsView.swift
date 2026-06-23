import SwiftUI

// MARK: - Data

struct PrayerNotifConfig: Identifiable, Codable, Equatable {
    let id: UUID
    let referenceTime: ReferenceTime
    var enabled: Bool
    var xMinutes: Int
    var atPrayerTime: Bool
    var zEnabled: Bool
    var zMinutes: Int
    var sound: AppSound
    var customSoundFilename: String?  // e.g. "my_adhan.caf" in App Support/Miqat/CustomSounds

    init(referenceTime: ReferenceTime, enabled: Bool, xMinutes: Int, atPrayerTime: Bool,
         zEnabled: Bool, zMinutes: Int, sound: AppSound, customSoundFilename: String? = nil) {
        self.id                  = UUID()
        self.referenceTime       = referenceTime
        self.enabled             = enabled
        self.xMinutes            = xMinutes
        self.atPrayerTime        = atPrayerTime
        self.zEnabled            = zEnabled
        self.zMinutes            = zMinutes
        self.sound               = sound
        self.customSoundFilename = customSoundFilename
    }

    var soundDisplayName: String {
        if sound == .custom, let name = customSoundFilename {
            return name.replacingOccurrences(of: ".caf", with: "")
        }
        return sound.displayName
    }
}

// MARK: - Generic Tiles

// One generic accordion row per prayer
struct NotifPrayerRow: View {
    @Binding var config: PrayerNotifConfig
    var onUpdate: (PrayerNotifConfig) -> Void = { _ in }
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
                .padding(.leading, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().padding(.horizontal, 32).opacity(0.25)

            // SOUND PICKER DISABLED: UNNotificationSound custom sound unreliable on macOS (Apple bug FB11642483). Re-enable when fixed.
//            SettingsDetailRow(
//                icon: "speaker.wave.2.fill",
//                iconColor: config.referenceTime.color,
//                title: "Sound",
//                value: config.soundDisplayName
//            ) { showSoundPicker = true }
//            .sheet(isPresented: $showSoundPicker) {
//                SoundPickerDialog(current: config.sound, currentCustomFilename: config.customSoundFilename) { sound, filename in
//                    config.sound = sound
//                    config.customSoundFilename = filename
//                }
//            }
        }
        .animation(.spring(duration: 0.18), value: config.zEnabled)
        .onChange(of: config) { _, newVal in onUpdate(newVal) }
    }

    private var summaryText: String {
        var parts: [String] = ["\(config.xMinutes)m early"]
        if config.atPrayerTime { parts.append("at prayer") }
        if config.zEnabled { parts.append("jamaat +\(config.zMinutes)m") }
        return parts.joined(separator: " · ")
    }
}

// Friday Jumu'ah row — uses same NotifAccordionRow generic component
struct FridayJumuahRow: View {
    @Binding var config: FridayJumuahConfig
    var onUpdate: (FridayJumuahConfig) -> Void = { _ in }
    @State private var showSoundPicker = false

    var body: some View {
        NotifAccordionRow(
            icon: "moon.stars.fill",
            iconColor: AppColor.accentGold,
            title: "Friday Jumu'ah",
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
                .padding(.leading, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider().padding(.horizontal, 32).opacity(0.25)

            // SOUND PICKER DISABLED: UNNotificationSound custom sound unreliable on macOS (Apple bug FB11642483). Re-enable when fixed.
//            SettingsDetailRow(
//                icon: "speaker.wave.2.fill",
//                iconColor: ReferenceTime.dhuhr.color,
//                title: "Sound",
//                value: config.sound.displayName
//            ) { showSoundPicker = true }
//            .sheet(isPresented: $showSoundPicker) {
//                SoundPickerDialog(current: config.sound, currentCustomFilename: nil) { sound, _ in
//                    config.sound = sound
//                }
//            }
        }
        .animation(.spring(duration: 0.18), value: config.missedEnabled)
        .onChange(of: config) { _, newVal in onUpdate(newVal) }
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
    var onUpdate: (KahfAnchorConfig) -> Void = { _ in }
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
        .onChange(of: config) { _, newVal in onUpdate(newVal) }
    }
}

// Flat row inside test card: icon | title + subtitle | trailing Send
struct TestNotifItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let onSend: () -> Void

    @State private var sent = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onSend()
                withAnimation { sent = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { sent = false }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sent ? "checkmark.circle.fill" : "paperplane.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(sent ? "Sent!" : "Send")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(sent ? AppColor.accentTeal : iconColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(sent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
    @Environment(NotificationViewModel.self) private var vm
    @State private var testSent              = false
    @State private var testCardExpanded      = false
    @State private var showPendingDebug      = false

    private var notifManager: NotificationManager { vm.notifManager }
    private var configs:      [PrayerNotifConfig]  { vm.prayerConfigs }
    private var allEnabled:   Bool                 { vm.allEnabled }
    private var mulkConfig:   SurahMulkConfig      { vm.mulkConfig }
    private var kahfConfig:   SurahKahfConfig      { vm.kahfConfig }
    private var jumuahConfig: FridayJumuahConfig   { vm.jumuahConfig }

    // Bindable wrapper for bvm.x bindings used in computed vars
    private var bvm: Bindable<NotificationViewModel> { Bindable(vm) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if notifManager.permissionState != .granted {
                        permissionBanner
                    }

                    let configEnabled = notifManager.permissionState == .granted

                    Group {
                        prayerAlertsCard
                        actionsCard
                        generalCard
                        surahMulkCard
                        surahKahfCard
                        testNotificationCard
                    }
                    .disabled(!configEnabled)
                    .opacity(configEnabled ? 1 : 0.4)
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await notifManager.checkPermission() }
        .onDisappear { notifManager.stopListeningForPermissionChange() }
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
                Toggle("", isOn: Binding(
                    get: { vm.allEnabled },
                    set: { vm.setAllEnabled($0) }
                ))
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
                let bindable = Bindable(vm)
                ForEach(vm.prayerConfigs.indices, id: \.self) { index in
                    NotifPrayerRow(config: bindable.prayerConfigs[index]) { updated in
                        vm.updatePrayerConfig(updated)
                    }
                        .disabled(!allEnabled)
                        .opacity(allEnabled ? 1 : 0.45)
                    Divider().padding(.leading, 52).opacity(0.3)
                }

                // Friday Jumu'ah — separate config inside same card
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(AppColor.accentGreen.opacity(0.7))
                    Text("FRIDAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColor.accentGreen.opacity(0.7))
                        .kerning(1)
                    Rectangle()
                        .fill(AppColor.accentGreen.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                FridayJumuahRow(config: bvm.jumuahConfig) { updated in
                    vm.updateJumuahConfig(updated)
                }
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
                isOn: bvm.dndEnabled
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
            // Header — tap to expand/collapse
            Button {
                withAnimation(.spring(duration: 0.25)) { testCardExpanded.toggle() }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColor.accentTeal)
                        .frame(width: 28, height: 28)
                        .background(AppColor.accentTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

                    Text("Test Notifications")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: testCardExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                showPendingDebug = true
            })
            .sheet(isPresented: $showPendingDebug) {
                PendingNotificationsDialog()
            }

            if testCardExpanded {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 16).opacity(0.4)

                    // Prayer rows
                    ForEach(vm.prayerConfigs) { config in
                        TestNotifItemRow(
                            icon: config.referenceTime.icon,
                            iconColor: config.referenceTime.color,
                            title: config.referenceTime.label,
                            subtitle: "\(config.xMinutes)m before · at prayer · jamaat +\(config.zMinutes)m"
                        ) {
                            notifManager.sendTestNotification(
                                prayerName: config.referenceTime.label,
                                sound: config.sound,
                                customSoundFilename: config.customSoundFilename
                            )
                        }
                        Divider().padding(.leading, 58).opacity(0.2)
                    }

                    // Surah Mulk
                    TestNotifItemRow(
                        icon: "moon.stars.fill",
                        iconColor: ReferenceTime.isha.color,
                        title: "Surah Mulk",
                        subtitle: "After Isha +\(mulkConfig.minutesAfterIsha)m · \(mulkConfig.sound.displayName)"
                    ) {
                        notifManager.sendTestNotification(prayerName: "Surah Mulk")
                    }

                    Divider().padding(.leading, 58).opacity(0.2)

                    // Surah Kahf
                    TestNotifItemRow(
                        icon: "book.fill",
                        iconColor: AppColor.accentGreen,
                        title: "Surah Kahf",
                        subtitle: kahfConfig.anchors.first(where: { $0.enabled })?.anchor.displayName ?? "No anchor enabled"
                    ) {
                        notifManager.sendTestNotification(prayerName: "Surah Kahf")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: Permission banner
    private var permissionBanner: some View {
        let isDenied  = notifManager.permissionState == .denied
        let accent    = isDenied ? AppColor.alert : AppColor.accentTeal

        return HStack(spacing: 14) {
            Image(systemName: isDenied ? "bell.slash.fill" : "bell.badge.fill")
                .font(.system(size: 13))
                .foregroundStyle(accent)
                .frame(width: 28, height: 28)
                .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(isDenied ? "Notifications Blocked" : "Enable Notifications")
                    .font(.system(size: 13, weight: .semibold))
                Text(isDenied ? "Notifications blocked in System Settings" : "Tap to allow prayer reminders")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if isDenied {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                    notifManager.startListeningForPermissionChange()
                } else {
                    Task { await notifManager.requestPermission() }
                }
            } label: {
                Text(isDenied ? "Open Settings" : "Enable")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1))
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

                Toggle("", isOn: Binding(
                    get: { vm.mulkConfig.enabled },
                    set: { val in var c = vm.mulkConfig; c.enabled = val; vm.updateMulkConfig(c) }
                ))
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
                    value: Binding(
                        get: { vm.mulkConfig.minutesAfterIsha },
                        set: { val in var c = vm.mulkConfig; c.minutesAfterIsha = val; vm.updateMulkConfig(c) }
                    ),
                    range: 5...120,
                    step: 5,
                    unit: "min",
                    showSign: false
                )
                .transition(.opacity.combined(with: .move(edge: .top)))

                Divider().padding(.horizontal, 32).opacity(0.25)

                // mulkSoundRow — DISABLED: sound picker commented out (Apple bug FB11642483)
            }
        }
        .animation(.spring(duration: 0.22), value: mulkConfig.enabled)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // SOUND PICKER DISABLED: UNNotificationSound custom sound unreliable on macOS (Apple bug FB11642483). Re-enable when fixed.
//    @State private var showMulkSoundPicker = false
//    private var mulkSoundRow: some View {
//        SettingsDetailRow(
//            icon: "speaker.wave.2.fill",
//            iconColor: ReferenceTime.isha.color,
//            title: "Sound",
//            value: mulkConfig.sound.displayName
//        ) { showMulkSoundPicker = true }
//        .sheet(isPresented: $showMulkSoundPicker) {
//            SoundPickerDialog(current: mulkConfig.sound, currentCustomFilename: nil) { sound, _ in
//                var updated = vm.mulkConfig
//                updated.sound = sound
//                vm.updateMulkConfig(updated)
//            }
//        }
//    }

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

            ForEach(vm.kahfConfig.anchors.indices, id: \.self) { index in
                KahfAnchorRow(config: bvm.kahfConfig.anchors[index]) { updated in
                    vm.updateKahfAnchor(updated)
                }
                if index != vm.kahfConfig.anchors.indices.last {
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
                isOn: bvm.iPrayedEnabled
            )

            Divider().padding(.leading, 52).opacity(0.3)

            NotifToggleRow(
                icon: "clock.arrow.circlepath",
                iconColor: AppColor.accentGold,
                label: "Snooze (5 min)",
                subtitle: "Remind again if dismissed without marking",
                isOn: bvm.snoozeEnabled
            )
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
