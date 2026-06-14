import AppKit
import SwiftUI

private enum WindowID {
    static let onboarding = "onboarding"
}

@main
struct NotypoApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environment(appState)
        } label: {
            MenuBarLabel()
                .environment(appState)
        }

        Window("Welcome to Notypo", id: WindowID.onboarding) {
            OnboardingWindowContent()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Settings {
            SettingsView()
                .environment(AccessibilityManager.shared)
                .environment(LaunchManager.shared)
                .environment(ProofreadService.shared)
        }
    }
}

private struct MenuBarLabel: View {

    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    @State private var proofreadPanel: Panel?

    var body: some View {
        Image(systemName: appState.isRunning ? "eyes" : "eyes.inverse")
            .onChange(of: appState.needsOnboarding, initial: true) { _, needs in
                guard needs else { return }
                NSApp.show()
                openWindow(id: WindowID.onboarding)
            }
            // React in onChange, not a didSet on the observed state, to avoid AppKit work mid-update.
            .onChange(of: appState.currentSession?.id) {
                syncProofreadPanel()
            }
    }

    private func syncProofreadPanel() {
        proofreadPanel?.hide()
        guard let session = appState.currentSession else {
            proofreadPanel = nil
            return
        }
        let panel = Panel(ProofreadView(session: session), level: .floating)
        panel.show()
        proofreadPanel = panel
    }
}

private struct OnboardingWindowContent: View {

    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        OnboardingView {
            dismissWindow(id: WindowID.onboarding)
            NSApp.hide()
        }
        .environment(AccessibilityManager.shared)
        .environment(ProofreadService.shared)
    }
}
