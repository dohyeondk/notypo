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

        // Onboarding is a plain, content-sized SwiftUI window. It never opens
        // automatically; the menu-bar label opens it at launch when needed.
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

/// The menu-bar status item, plus the bridges that turn `AppState` into
/// window/panel presentation. Living in the always-rendered status item, its
/// `onChange` handlers fire as reactions *after* the update completes — a safe
/// place to do imperative AppKit work, unlike an observed property's `didSet`.
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
            .onChange(of: appState.currentSession?.id) {
                syncProofreadPanel()
            }
    }

    /// Shows the floating, non-activating proofread panel for the current
    /// session, or tears it down when there is none.
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

/// Wraps `OnboardingView` so it can dismiss its own window scene on completion.
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
