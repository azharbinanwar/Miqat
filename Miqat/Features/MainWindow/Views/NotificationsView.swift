import SwiftUI

// MARK: - Data

enum AzanSound: String, CaseIterable {
    case mecca   = "Mecca"
    case medina  = "Medina"
    case default_ = "Default"
}

struct PrayerNotifConfig: Identifiable {
    let id = UUID()
    let referenceTime: ReferenceTime
    var enabled: Bool
    var reminderMinutes: Int
    var secondReminder: Bool
    var sound: AzanSound
    var volume: Double             // 0.0 – 1.0
}

// MARK: - Generic Tiles

// One generic accordion row per prayer
struct NotifPrayerRow: View {
    @Binding var config: PrayerNotifConfig
    @State private var expanded  = false
    @State private var isPlaying = false

    private let minuteOptions = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header — always visible
            Button { withAnimation(.spring(duration: 0.22)) { expanded.toggle() } } label: {
                HStack(spacing: 14) {
                    Image(systemName: config.referenceTime.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(config.enabled ? config.referenceTime.color : .secondary.opacity(0.35))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.referenceTime.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(config.enabled ? .primary : .secondary)

                        if config.enabled {
                            Text(summaryText)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if config.enabled {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                            .padding(.trailing, 4)
                    }

                    Toggle("", isOn: $config.enabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(config.referenceTime.color)
                        .onChange(of: config.enabled) { _, on in
                            if !on { withAnimation { expanded = false } }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!config.enabled)

            // Expanded detail panel
            if expanded && config.enabled {
                VStack(spacing: 0) {
                    Divider().padding(.horizontal, 16).opacity(0.3)

                    // Reminder time
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(config.referenceTime.color.opacity(0.7))
                            .frame(width: 20)

                        Text("Remind me")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Minute picker
                        HStack(spacing: 4) {
                            ForEach(minuteOptions, id: \.self) { min in
                                Button {
                                    withAnimation(.spring(duration: 0.15)) {
                                        config.reminderMinutes = min
                                    }
                                } label: {
                                    Text("\(min)m")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(config.reminderMinutes == min ? .white : .secondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 5)
                                        .background(
                                            config.reminderMinutes == min
                                                ? config.referenceTime.color
                                                : Color(NSColor.controlBackgroundColor),
                                            in: RoundedRectangle(cornerRadius: 6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 32).opacity(0.25)

                    // Second reminder toggle
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(config.referenceTime.color.opacity(0.7))
                            .frame(width: 20)

                        Text("Also alert at prayer time")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Toggle("", isOn: $config.secondReminder)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .tint(config.referenceTime.color)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 32).opacity(0.25)

                    // Sound picker + play button
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(config.referenceTime.color.opacity(0.7))
                            .frame(width: 20)

                        Text("Sound")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 6) {
                            // Sound picker
                            HStack(spacing: 0) {
                                ForEach(AzanSound.allCases, id: \.self) { s in
                                    Button {
                                        withAnimation(.spring(duration: 0.15)) { config.sound = s }
                                    } label: {
                                        Text(s.rawValue)
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(config.sound == s ? .white : .secondary)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 5)
                                            .background(
                                                config.sound == s ? config.referenceTime.color : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 6)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color(NSColor.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.primary.opacity(0.08), lineWidth: 1))

                            // Play preview button
                            Button {
                                withAnimation(.spring(duration: 0.2)) { isPlaying.toggle() }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { isPlaying = false }
                                }
                            } label: {
                                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(config.referenceTime.color)
                                    .frame(width: 28, height: 28)
                                    .background(config.referenceTime.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
                                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(config.referenceTime.color.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider().padding(.horizontal, 32).opacity(0.25)

                    // Volume slider
                    HStack(spacing: 12) {
                        Image(systemName: config.volume < 0.1 ? "speaker.slash.fill" :
                              config.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(config.referenceTime.color.opacity(0.7))
                            .frame(width: 20)

                        Text("Volume")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Slider(value: $config.volume, in: 0...1)
                            .tint(config.referenceTime.color)

                        Text("\(Int(config.volume * 100))%")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.primary.opacity(0.03))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var summaryText: String {
        var parts: [String] = ["\(config.reminderMinutes) min early"]
        if config.secondReminder { parts.append("at prayer") }
        parts.append(config.sound.rawValue)
        return parts.joined(separator: " · ")
    }
}

// One generic toggle row for general settings
struct NotifToggleRow: View {
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
                .frame(width: 20)

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
        .padding(.vertical, 12)
    }
}

// MARK: - Notifications View

struct NotificationsView: View {
    @State private var configs: [PrayerNotifConfig] = [
        PrayerNotifConfig(referenceTime: .fajr,    enabled: true,  reminderMinutes: 20, secondReminder: true,  sound: .medina,   volume: 1.0),
        PrayerNotifConfig(referenceTime: .dhuhr,   enabled: true,  reminderMinutes: 20, secondReminder: false, sound: .default_, volume: 0.7),
        PrayerNotifConfig(referenceTime: .asr,     enabled: true,  reminderMinutes: 30, secondReminder: true,  sound: .mecca,    volume: 0.8),
        PrayerNotifConfig(referenceTime: .maghrib, enabled: true,  reminderMinutes: 15, secondReminder: true,  sound: .mecca,    volume: 0.8),
        PrayerNotifConfig(referenceTime: .isha,    enabled: false, reminderMinutes: 20, secondReminder: false, sound: .default_, volume: 0.6),
    ]

    @State private var allEnabled      = true
    @State private var iPrayedAction   = true
    @State private var snoozeEnabled   = true
    @State private var respectDND      = true
    @State private var testSent        = false
    @State private var selectedTestPrayer: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    prayerAlertsCard
                    generalCard
                    actionsCard
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
                    .tint(AppColor.teal)
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
                    if config.id != configs.last?.id {
                        Divider().padding(.leading, 52).opacity(0.3)
                    }
                }
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
                title: "Respect Focus / DND",
                subtitle: "Silence during macOS Focus modes",
                isOn: $respectDND
            )

            Divider().padding(.leading, 52).opacity(0.3)

            NotifToggleRow(
                icon: "bell.badge.slash.fill",
                iconColor: AppColor.amber,
                title: "Fajr Exception",
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
                        testSent ? AppColor.teal : configs[selectedTestPrayer].referenceTime.color,
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
                iconColor: AppColor.teal,
                title: "\"I Prayed\" Quick Action",
                subtitle: "Mark prayer from the notification banner",
                isOn: $iPrayedAction
            )

            Divider().padding(.leading, 52).opacity(0.3)

            NotifToggleRow(
                icon: "clock.arrow.circlepath",
                iconColor: AppColor.amber,
                title: "Snooze (5 min)",
                subtitle: "Remind again if dismissed without marking",
                isOn: $snoozeEnabled
            )
            .padding(.bottom, 4)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}
