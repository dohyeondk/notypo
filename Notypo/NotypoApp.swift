import SwiftUI

@main
struct NotypoApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
        } label: {
            Image(systemName: "eyes.inverse")
        }

        Window("Settings", id: WindowID.settings.rawValue) {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.titleBar)
    }
}
