import SwiftUI

@main
struct MiqatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("🕌 Asr  42:18", systemImage: "moon.stars.fill") {
            Text("Miqat")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
