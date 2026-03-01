import SwiftUI

@main
struct NotypoApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
        } label: {
            Image(systemName: "eyes.inverse")
        }

        Window("Settings", id: WindowID.settings.rawValue) {
            SettingsView()
                .environment(appState.accessibilityManager)
                .environment(appState.proofreadService)
        }
        .defaultLaunchBehavior(appState.needsOnboarding ? .presented : .suppressed)
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
    }
}
