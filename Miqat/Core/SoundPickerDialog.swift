import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct SoundPickerDialog: View {
    let current: AppSound
    var onSelect: (AppSound, URL?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var playing: AppSound?
    @State private var player: AVAudioPlayer?

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Text("Choose Sound")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(AppSound.allCases.filter { $0 != .custom }, id: \.self) { sound in
                        soundRow(sound)
                        if sound != AppSound.allCases.filter({ $0 != .custom }).last {
                            Divider().padding(.leading, 60).opacity(0.4)
                        }
                    }
                }
            }

            Divider()

            // Pick from system files
            Button { pickFromFiles() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColor.accentTeal)
                        .frame(width: 32, height: 32)
                        .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pick from Files…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Text("Use any audio file from your Mac")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 360, height: 460)
        .onDisappear { stopPlaying() }
    }

    // MARK: - Sound Row

    @ViewBuilder
    private func soundRow(_ sound: AppSound) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rowIcon(sound))
                .font(.system(size: 16))
                .foregroundStyle(AppColor.accentTeal)
                .frame(width: 32, height: 32)
                .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(sound.displayName)
                    .font(.system(size: 13, weight: current == sound ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Text(sound.isAdhan ? "Adhan" : sound == .systemDefault ? "System" : "Notification")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Play / stop button
            if sound != .systemDefault {
                Button {
                    playing == sound ? stopPlaying() : play(sound)
                } label: {
                    Image(systemName: playing == sound ? "stop.fill" : "play.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColor.accentTeal)
                        .frame(width: 28, height: 28)
                        .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppColor.accentTeal.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Selected indicator
            if current == sound {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColor.accentTeal)
            } else {
                Color.clear.frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(current == sound ? AppColor.accentTeal.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(sound, nil)
            dismiss()
        }
    }

    private func rowIcon(_ sound: AppSound) -> String {
        switch sound {
        case .adhanOmarHisham:           return "waveform"
        case .hayyaAlasSalah, .hayyaAlasFalah: return "waveform.badge.mic"
        case .bellRing:                  return "bell.fill"
        case .systemDefault:             return "speaker.wave.2.fill"
        default:                         return "waveform"
        }
    }

    // MARK: - Playback

    private func play(_ sound: AppSound) {
        stopPlaying()

        if sound == .systemDefault {
            NSSound.beep()
            return
        }

        guard let filename = sound.filename else { return }

        // Try with subfolder first, then flat bundle root
        let url = sound.folder.flatMap {
            Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Sounds/\($0)")
        } ?? Bundle.main.url(forResource: filename, withExtension: "mp3")

        guard let url else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            playing = sound
            let duration = player?.duration ?? 5
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if playing == sound { playing = nil }
            }
        } catch {
            playing = nil
        }
    }

    func playCustom(url: URL) {
        stopPlaying()
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        player = p
        player?.play()
    }

    private func stopPlaying() {
        player?.stop()
        player = nil
        playing = nil
    }

    // MARK: - File Picker

    private func pickFromFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose an audio file to use as notification sound"
        if panel.runModal() == .OK, let url = panel.url {
            onSelect(.custom, url)
            dismiss()
        }
    }
}
