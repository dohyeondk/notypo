import SwiftUI

@main
struct NotypoApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environment(appState)
        } label: {
            Image(systemName: ProofreadService.shared.isProcessing ? "eyes" : "eyes.inverse")
        }

        Window("Settings", id: WindowID.settings.rawValue) {
            SettingsView()
                .environment(AccessibilityManager.shared)
                .environment(ProofreadService.shared)
                .environment(CorrectionPresenter.shared)
        }
        .defaultLaunchBehavior(appState.needsOnboarding ? .presented : .suppressed)
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
    }
}
