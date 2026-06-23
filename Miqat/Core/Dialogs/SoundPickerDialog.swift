import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct SoundPickerDialog: View {
    let current: AppSound
    let currentCustomFilename: String?
    var onSelect: (AppSound, String?) -> Void  // (sound, customSoundFilename?)

    @Environment(\.dismiss) private var dismiss
    @State private var playing: String?         // identifier being previewed
    @State private var player: AVAudioPlayer?
    @State private var isConverting = false
    @State private var conversionError: String?
    @State private var savedCustomSounds: [String] = []

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

                    // Bundled sounds
                    ForEach(AppSound.allCases.filter { $0 != .custom }, id: \.self) { sound in
                        bundledRow(sound)
                        Divider().padding(.leading, 60).opacity(0.4)
                    }

                    // Saved custom sounds
                    if !savedCustomSounds.isEmpty {
                        sectionHeader("Custom Sounds")
                        ForEach(savedCustomSounds, id: \.self) { filename in
                            customRow(filename)
                            Divider().padding(.leading, 60).opacity(0.4)
                        }
                    }
                }
            }

            Divider()

            // Convert & import from Files
            if isConverting {
                HStack(spacing: 12) {
                    ProgressView().controlSize(.small)
                    Text("Converting sound…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            } else {
                Button { pickFromFiles() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColor.accentTeal)
                            .frame(width: 32, height: 32)
                            .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import from Files…")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text(conversionError ?? "Use any audio file from your Mac")
                                .font(.system(size: 11))
                                .foregroundStyle(conversionError != nil ? .red : .secondary)
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
        }
        .frame(width: 360, height: 480)
        .onAppear { savedCustomSounds = CustomSoundRepository.shared.all }
        .onDisappear { stopPlaying() }
    }

    // MARK: - Bundled sound row

    @ViewBuilder
    private func bundledRow(_ sound: AppSound) -> some View {
        let isSelected = current == sound && (sound != .custom)
        HStack(spacing: 12) {
            Image(systemName: rowIcon(sound))
                .font(.system(size: 16))
                .foregroundStyle(AppColor.accentTeal)
                .frame(width: 32, height: 32)
                .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(sound.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Text(sound.isAdhan ? "Adhan" : sound == .systemDefault ? "System" : "Notification")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if sound != .systemDefault {
                previewButton(id: sound.rawValue) { playBundled(sound) }
            }

            selectionMark(isSelected)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(isSelected ? AppColor.accentTeal.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(sound, nil)
            dismiss()
        }
    }

    // MARK: - Custom sound row

    @ViewBuilder
    private func customRow(_ filename: String) -> some View {
        let isSelected = current == .custom && currentCustomFilename == filename
        let displayName = filename.replacingOccurrences(of: ".caf", with: "")
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColor.accentGold)
                .frame(width: 32, height: 32)
                .background(AppColor.accentGold.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Text("Custom")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            previewButton(id: filename) { playCustom(filename: filename) }

            selectionMark(isSelected)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(isSelected ? AppColor.accentTeal.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(.custom, filename)
            dismiss()
        }
    }

    // MARK: - Shared sub-views

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func previewButton(id: String, action: @escaping () -> Void) -> some View {
        Button {
            playing == id ? stopPlaying() : action()
        } label: {
            Image(systemName: playing == id ? "stop.fill" : "play.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColor.accentTeal)
                .frame(width: 28, height: 28)
                .background(AppColor.accentTeal.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(AppColor.accentTeal.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func selectionMark(_ selected: Bool) -> some View {
        if selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColor.accentTeal)
        } else {
            Color.clear.frame(width: 16, height: 16)
        }
    }

    private func rowIcon(_ sound: AppSound) -> String {
        switch sound {
        case .adhanOmarHisham:                 return "waveform"
        case .hayyaAlasSalah, .hayyaAlasFalah: return "waveform.badge.mic"
        case .bellRing:                        return "bell.fill"
        case .systemDefault:                   return "speaker.wave.2.fill"
        default:                               return "waveform"
        }
    }

    // MARK: - Playback

    private func playBundled(_ sound: AppSound) {
        stopPlaying()
        guard let filename = sound.filename else { return }
        let url = sound.folder.flatMap {
            Bundle.main.url(forResource: filename, withExtension: "caf", subdirectory: "Sounds/\($0)")
        } ?? Bundle.main.url(forResource: filename, withExtension: "caf")
        guard let url else { return }
        play(url: url, id: sound.rawValue)
    }

    private func playCustom(filename: String) {
        stopPlaying()
        let url = SoundConversionService.shared.url(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        play(url: url, id: filename)
    }

    private func play(url: URL, id: String) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        player  = p
        playing = id
        p.play()
        let duration = p.duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if playing == id { playing = nil }
        }
    }

    private func stopPlaying() {
        player?.stop()
        player  = nil
        playing = nil
    }

    // MARK: - Import from Files

    private func pickFromFiles() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose an audio file to use as notification sound"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        isConverting   = true
        conversionError = nil

        Task {
            do {
                let filename = try await SoundConversionService.shared.importSound(from: url)
                CustomSoundRepository.shared.save(filename: filename)
                await MainActor.run {
                    savedCustomSounds = CustomSoundRepository.shared.all
                    isConverting = false
                    onSelect(.custom, filename)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isConverting    = false
                    conversionError = error.localizedDescription
                }
            }
        }
    }
}
