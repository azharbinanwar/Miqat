import SwiftUI
import AppKit

@Observable final class ThemeViewModel {
    private(set) var settings: ThemeSettings
    private let repo: ThemeRepository

    init(repo: ThemeRepository = UserDefaultsThemeRepository()) {
        self.repo     = repo
        self.settings = repo.load()
    }

    func update(_ block: (inout ThemeSettings) -> Void) {
        block(&settings)
        repo.save(settings)
    }

    func binding<T>(for keyPath: WritableKeyPath<ThemeSettings, T>) -> Binding<T> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    var accentColor: Color {
        let opts = AppColor.accentOptions
        guard settings.accentColorIndex >= 0, settings.accentColorIndex < opts.count else { return opts[0].color }
        return opts[settings.accentColorIndex].color
    }

    var colorScheme: ColorScheme {
        switch settings.appTheme {
        case .light:  return .light
        case .dark:   return .dark
        case .system:
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? .dark : .light
        }
    }
}
