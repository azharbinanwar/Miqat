import Foundation
import SwiftUI

extension Notification.Name {
    static let settingsDidChange = Notification.Name("MiqatSettingsDidChange")
    static let miqatSwitchTab    = Notification.Name("MiqatSwitchTab")
}

@Observable
final class SettingsViewModel {
    private(set) var settings: AppSettings
    private let storage: SettingsStorageProtocol

    init(storage: SettingsStorageProtocol = ServiceLocator.shared.resolve(SettingsStorageProtocol.self)) {
        self.storage = storage
        if let loaded = storage.load() {
            self.settings = loaded
        } else {
            self.settings = AppSettings()
            storage.save(self.settings)
        }
    }

    func update(_ modify: (inout AppSettings) -> Void) {
        modify(&settings)

        // Threshold validation: 5 ≤ red ≤ orange ≤ 60
        settings.redThreshold    = max(5, min(settings.redThreshold, settings.orangeThreshold))
        settings.orangeThreshold = max(settings.redThreshold, min(settings.orangeThreshold, 60))

        storage.save(settings)
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    func resetToDefaults() {
        update { $0 = AppSettings() }
    }

    func binding<T>(for keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}
