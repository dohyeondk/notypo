import SwiftUI

struct MenuContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Notypo is running")
            .disabled(true)

        Divider()

        Button("Settings…") {
            openWindow(id: WindowID.settings.rawValue)
            NSApp.show()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
