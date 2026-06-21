import Foundation

// Tracks user-imported custom sounds saved by SoundConversionService.
// Persists names to UserDefaults so the list survives restarts.
final class CustomSoundRepository {

    static let shared = CustomSoundRepository()
    private init() {}

    private let key = "miqat.customSoundFilenames"

    var all: [String] {
        get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    func save(filename: String) {
        guard !all.contains(filename) else { return }
        all = (all + [filename]).sorted()
    }

    func delete(filename: String) {
        all = all.filter { $0 != filename }
        try? SoundConversionService.shared.delete(filename: filename)
    }

    func url(for filename: String) -> URL {
        SoundConversionService.shared.url(for: filename)
    }

    // Call on launch to prune stale entries (file deleted outside app)
    func reconcile() {
        let existing = SoundConversionService.shared.savedSoundFilenames()
        all = all.filter { existing.contains($0) }
    }
}
