import KeyboardShortcuts
import SwiftUI

struct MenuContent: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Proofread") {
            Task { await appState.handleHotkey() }
        }
        .globalKeyboardShortcut(.proofread)

        Divider()

        Button("Settings…") {
            openWindow(id: WindowID.settings.rawValue)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
