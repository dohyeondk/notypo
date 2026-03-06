import SwiftUI

@main
struct NotypoApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environment(appState)
        } label: {
            Image(systemName: appState.isRunning ? "eyes" : "eyes.inverse")
        }

        Settings {
            SettingsView()
                .environment(AccessibilityManager.shared)
                .environment(LaunchManager.shared)
                .environment(ProofreadService.shared)
        }
    }
}
