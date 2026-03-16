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
                    if accessibilityManager.isGranted {
                        Label("Access Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access") {
                            accessibilityManager.requestPermission()
                        }
                    }
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
    @State private var mlxModelManager = MLXModelManager.shared
    @State private var apiKeyInput = ""
    @State private var customModelInput = ""
    @State private var customMLXModelInput = ""

    private var isCustomModel: Bool {
        !OpenAIModel.all.contains(where: { $0.id == proofreadService.openAIModel })
    }

    private var isCustomMLXModel: Bool {
        !MLXModel.all.contains(where: { $0.id == mlxModelManager.modelID })
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        @Bindable var service = proofreadService
        @Bindable var mlx = mlxModelManager

        Form {
            Picker("Provider", selection: $service.selectedProvider) {
                ForEach(LLMProviderType.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }

            switch proofreadService.selectedProvider {
            case .appleIntelligence:
                LabeledContent("Status") {
                    switch proofreadService.appleIntelligenceAvailability {
                    case .available:
                        Label("Ready", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .unavailable(.appleIntelligenceNotEnabled):
                        Button("Enable Apple Intelligence") {
                            proofreadService.openAppleIntelligenceSettings()
                        }
                    case .unavailable(.deviceNotEligible):
                        Text("Device not eligible")
                            .foregroundStyle(.secondary)
                    case .unavailable(.modelNotReady):
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading model…")
                                .foregroundStyle(.secondary)
                        }
                    case .unavailable:
                        Text("Unavailable")
                            .foregroundStyle(.secondary)
                    }
                }

            case .openAI:
                SecureField("API Key", text: $apiKeyInput)
                    .onSubmit {
                        proofreadService.openAIAPIKey = apiKeyInput
                    }
                    .onChange(of: apiKeyInput) {
                        proofreadService.openAIAPIKey = apiKeyInput
                    }

                Picker("Model", selection: $service.openAIModel) {
                    ForEach(OpenAIModel.all) { model in
                        Text("\(model.name)  (\(model.inputPrice) in / \(model.outputPrice) out)")
                            .tag(model.id)
                    }
                    Divider()
                    Text("Custom").tag("__custom__")
                }
                .onChange(of: proofreadService.openAIModel) {
                    if proofreadService.openAIModel == "__custom__" {
                        proofreadService.openAIModel = customModelInput.isEmpty
                            ? "" : customModelInput
                    }
                }

                if isCustomModel {
                    TextField("Custom Model ID", text: $customModelInput)
                        .onChange(of: customModelInput) {
                            proofreadService.openAIModel = customModelInput
                        }
                }

            case .localMLX:
                Picker("Model", selection: $mlx.modelID) {
                    ForEach(MLXModel.all) { model in
                        Text(
                            "\(model.name)\(model.isExperimental ? " (Experimental)" : "")  (\(model.size))"
                        )
                            .tag(model.id)
                    }
                    Divider()
                    Text("Custom").tag("__custom_mlx__")
                }
                .onChange(of: mlxModelManager.modelID) {
                    if mlxModelManager.modelID == "__custom_mlx__" {
                        mlxModelManager.modelID = customMLXModelInput.isEmpty
                            ? "" : customMLXModelInput
                    }
                }

                if isCustomMLXModel {
                    TextField("Hugging Face Model ID", text: $customMLXModelInput)
                        .onChange(of: customMLXModelInput) {
                            mlxModelManager.modelID = customMLXModelInput
                        }
                }

                LabeledContent("Status") {
                    switch mlxModelManager.status {
                    case .idle:
                        Button("Download & Load") {
                            Task { await mlxModelManager.load() }
                        }
                    case .downloading(let progress):
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                ProgressView(value: progress.fraction)
                                    .frame(width: 120)
                                Button {
                                    mlxModelManager.cancel()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Cancel download")
                            }
                            HStack(spacing: 6) {
                                Text("\(Int(progress.fraction * 100))%")
                                if progress.filesTotal > 0 {
                                    Text("·")
                                    Text("\(progress.filesCompleted)/\(progress.filesTotal) files")
                                }
                                if progress.bytesPerSecond > 0 {
                                    Text("·")
                                    Text("\(formatBytes(Int64(progress.bytesPerSecond)))/s")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        }
                    case .loading:
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading model…")
                                .foregroundStyle(.secondary)
                        }
                    case .ready:
                        HStack(spacing: 8) {
                            Label("Ready", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Button("Unload") {
                                mlxModelManager.unload()
                            }
                            .controlSize(.small)
                        }
                    case .failed(let message):
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Button("Retry") {
                                Task { await mlxModelManager.load() }
                            }
                            .controlSize(.small)
                        }
                    }
                }

                if MLXModel.all.first(where: { $0.id == mlxModelManager.modelID })?.isExperimental == true {
                    Text(
                        "Qwen 3.5 is experimental here because it can fail to terminate cleanly in this app."
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                TextField(text: $service.toneGuide, axis: .vertical) {
                    Text("Tone Guide")
                }
                .lineLimit(5...10)
            } footer: {
                Text("Optional. Guides the AI's writing style, e.g. \"Keep a professional but friendly tone.\"")
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.columns)
        .padding()
        .onAppear {
            apiKeyInput = proofreadService.openAIAPIKey
            if isCustomModel {
                customModelInput = proofreadService.openAIModel
            }
            if isCustomMLXModel {
                customMLXModelInput = mlxModelManager.modelID
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        Self.byteFormatter.string(fromByteCount: bytes)
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
