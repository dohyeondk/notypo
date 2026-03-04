import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(ProofreadService.self) private var proofreadService
    
    var body: some View {
        @Bindable var proofreadService = proofreadService

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

            Section("Shortcut") {
                KeyboardShortcuts.Recorder("Proofread:", name: .proofread)
            }

            Section("Proofreading") {
                LabeledContent("Model") {
                    switch proofreadService.availability {
                    case .available:
                        Text("Ready")
                            .foregroundStyle(.green)
                    case .unavailable(.appleIntelligenceNotEnabled):
                        Button("Enable Apple Intelligence") {
                            proofreadService.openAppleIntelligenceSettings()
                        }
                    case .unavailable(.deviceNotEligible):
                        Text("Device not eligible")
                            .foregroundStyle(.secondary)
                    case .unavailable(.modelNotReady):
                        Text("Model downloading…")
                            .foregroundStyle(.secondary)
                    case .unavailable:
                        Text("Model unavailable")
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Tone Guide") {
                    TextField("e.g. casual, formal", text: $proofreadService.toneGuide)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("General") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 360)
        .onAppear {
            NSApp.show()
        }
        .onDisappear {
            NSApp.hide()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AccessibilityManager.shared)
        .environment(ProofreadService.shared)
}
