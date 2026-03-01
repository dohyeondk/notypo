import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 120)
        .onAppear {
            NSApp.show()
        }
        .onDisappear {
            NSApp.hide()
        }
    }
}
