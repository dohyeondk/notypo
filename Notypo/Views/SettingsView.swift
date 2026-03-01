import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(ProofreadService.self) private var proofreadService
    @Environment(CorrectionPresenter.self) private var correctionPresenter

    var body: some View {
        @Bindable var proofreadService = proofreadService
        @Bindable var correctionPresenter = correctionPresenter

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

            Section("Correction Panel") {
                LabeledContent("Dismiss After") {
                    Stepper("\(correctionPresenter.dismissDuration, specifier: "%.0f")s", value: $correctionPresenter.dismissDuration, in: 1...60, step: 1)
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
        .environment(CorrectionPresenter.shared)
}
