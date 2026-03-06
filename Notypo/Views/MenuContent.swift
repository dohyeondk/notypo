import KeyboardShortcuts
import SwiftUI

struct MenuContent: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        Button("Proofread") {
            Task { await appState.handleHotkey() }
        }
        .globalKeyboardShortcut(.hotkey)

        Divider()

        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
