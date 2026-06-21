import AVFoundation
import Foundation

final class SoundConversionService {

    static let shared = SoundConversionService()
    private init() {
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    // App Support/Miqat/CustomSounds — writable in sandboxed app
    var storageDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Miqat/CustomSounds", isDirectory: true)
    }

    // MARK: - Public API

    // Takes a user-picked URL (security-scoped), converts to .caf, saves to storageDirectory.
    // Returns the saved filename (e.g. "my_adhan.caf") for use with UNNotificationSound or playback.
    func importSound(from sourceURL: URL) async throws -> String {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        let stem     = sourceURL.deletingPathExtension().lastPathComponent
        let filename = stem + ".caf"
        let destURL  = storageDirectory.appendingPathComponent(filename)

        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }

        try await convertToCaf(from: sourceURL, to: destURL)
        print("🎵 SoundConversionService: imported \(filename)")
        return filename
    }

    func url(for filename: String) -> URL {
        storageDirectory.appendingPathComponent(filename)
    }

    func savedSoundFilenames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: storageDirectory.path))?
            .filter { $0.hasSuffix(".caf") }
            .sorted() ?? []
    }

    func delete(filename: String) throws {
        let url = storageDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
        print("🗑 SoundConversionService: deleted \(filename)")
    }

    // MARK: - Conversion

    // Decodes any audio format to raw PCM then writes into a CAF container.
    // CAF/PCM is what UNNotificationSound and AVAudioPlayer both accept cleanly.
    private func convertToCaf(from source: URL, to dest: URL) async throws {
        let asset  = AVURLAsset(url: source)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else { throw ConversionError.noAudioTrack }

        let pcm: [String: Any] = [
            AVFormatIDKey:             Int(kAudioFormatLinearPCM),
            AVSampleRateKey:           44100,
            AVNumberOfChannelsKey:     1,
            AVLinearPCMBitDepthKey:    16,
            AVLinearPCMIsFloatKey:     false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let reader = try AVAssetReader(asset: asset)
        let readerOut = AVAssetReaderTrackOutput(track: track, outputSettings: pcm)
        reader.add(readerOut)

        let writer   = try AVAssetWriter(outputURL: dest, fileType: .caf)
        let writerIn = AVAssetWriterInput(mediaType: .audio, outputSettings: pcm)
        writerIn.expectsMediaDataInRealTime = false
        writer.add(writerIn)

        guard reader.startReading() else { throw ConversionError.readerFailed(reader.error) }
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            writerIn.requestMediaDataWhenReady(on: .global(qos: .userInitiated)) {
                while writerIn.isReadyForMoreMediaData {
                    if let buf = readerOut.copyNextSampleBuffer() {
                        writerIn.append(buf)
                    } else {
                        writerIn.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                cont.resume()
                            } else {
                                cont.resume(throwing: writer.error ?? ConversionError.writerFailed)
                            }
                        }
                        return
                    }
                }
            }
        }
    }

    // MARK: - Errors

    enum ConversionError: Error, LocalizedError {
        case noAudioTrack
        case readerFailed(Error?)
        case writerFailed

        var errorDescription: String? {
            switch self {
            case .noAudioTrack:        return "No audio track found in this file"
            case .readerFailed(let e): return "Could not read audio: \(e?.localizedDescription ?? "unknown")"
            case .writerFailed:        return "Could not write converted audio"
            }
        }
    }
}
