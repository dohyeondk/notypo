import SwiftUI

struct SettingsView: View {
    @Environment(AccessibilityManager.self) private var accessibilityManager

    var body: some View {
        Form {
            Section("Permissions") {
                LabeledContent("Accessibility") {
                    if accessibilityManager.isGranted {
                        Text("Enabled")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access") {
                            accessibilityManager.requestPermission()
                        }
                    }
                }
            }

            Section("General") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 200)
        .onAppear {
            NSApp.show()
        }
        .onDisappear {
            NSApp.hide()
        }
    }
}
