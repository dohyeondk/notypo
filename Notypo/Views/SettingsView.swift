import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                GeneralTab()
            }
            Tab("Proofreading", systemImage: "text.badge.checkmark") {
                ProofreadingTab()
            }
            Tab("About", systemImage: "info.circle") {
                AboutTab()
            }
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            NSApp.show()
        }
        .onDisappear {
            NSApp.hide()
        }
    }
}

// MARK: - General

private struct GeneralTab: View {
    @Environment(AccessibilityManager.self) private var accessibilityManager
    @Environment(LaunchManager.self) private var launchManager

    var body: some View {
        @Bindable var launchManager = launchManager

        Form {
            Section {
                LabeledContent("Start Up") {
                    Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                }
            }

            Section {
                LabeledContent("Accessibility") {
                    Button("Grant Access") {
                        accessibilityManager.requestPermission()
                    }
                    .disabled(accessibilityManager.isGranted)
                }
            }
            
            Section {
                KeyboardShortcuts.Recorder("Hotkey", name: .hotkey)
            }
        }
        .formStyle(.columns)
        .padding()
    }
}

// MARK: - Proofreading

private struct ProofreadingTab: View {
    @Environment(ProofreadService.self) private var proofreadService

    var body: some View {
        @Bindable var proofreadService = proofreadService

        Form {
            LabeledContent("Model") {
                switch proofreadService.availability {
                case .available:
                    Text("Ready")
                        .foregroundStyle(.primary)
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
            
            TextField(text: $proofreadService.toneGuide, axis: .vertical) {
                Text("Tone Guide")
            }
            .lineLimit(5...10)
        }
        .formStyle(.columns)
        .padding()
    }
}

// MARK: - About

private struct AboutTab: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: 2) {
                Text("Notypo")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AccessibilityManager.shared)
        .environment(LaunchManager.shared)
        .environment(ProofreadService.shared)
}
