import AppKit
import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class ProofreadService {

    static let shared = ProofreadService()

    var appleIntelligenceAvailability: SystemLanguageModel.Availability = SystemLanguageModel.default.availability

    private static let toneGuideKey = "toneGuide"
    private static let providerKey = "selectedProvider"
    private static let openAIModelKey = "openAIModel"
    private static let openAIAPIKeyAccount = "openai-api-key"

    var toneGuide: String = UserDefaults.standard.string(forKey: toneGuideKey) ?? "" {
        didSet { UserDefaults.standard.set(toneGuide, forKey: Self.toneGuideKey) }
    }

    var selectedProvider: LLMProviderType = {
        if let raw = UserDefaults.standard.string(forKey: providerKey),
           let value = LLMProviderType(rawValue: raw) {
            return value
        }
        return .appleIntelligence
    }() {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: Self.providerKey) }
    }

    var openAIModel: String = UserDefaults.standard.string(forKey: openAIModelKey) ?? OpenAIModel.all.last!.id {
        didSet { UserDefaults.standard.set(openAIModel, forKey: Self.openAIModelKey) }
    }

    var openAIAPIKey: String {
        get { KeychainHelper.load(account: Self.openAIAPIKeyAccount) ?? "" }
        set {
            if newValue.isEmpty {
                KeychainHelper.delete(account: Self.openAIAPIKeyAccount)
            } else {
                KeychainHelper.save(account: Self.openAIAPIKeyAccount, value: newValue)
            }
        }
    }

    var isAvailable: Bool {
        switch selectedProvider {
        case .appleIntelligence:
            appleIntelligenceAvailability == .available
        case .openAI:
            !openAIAPIKey.isEmpty
        case .localMLX:
            true
        }
    }

    func ensureProvider() async throws -> any LLMProvider {
        switch selectedProvider {
        case .appleIntelligence:
            return AppleIntelligenceProvider()
        case .openAI:
            return OpenAIProvider(apiKey: openAIAPIKey, model: openAIModel)
        case .localMLX:
            if !MLXModelManager.shared.isReady {
                await MLXModelManager.shared.load()
            }
            guard let provider = MLXModelManager.shared.makeProvider() else {
                throw MLXProviderError.modelNotLoaded
            }
            return provider
        }
    }

    private var pollingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    func startMonitoring() {
        pollingTask = Task {
            while !Task.isCancelled {
                appleIntelligenceAvailability = SystemLanguageModel.default.availability
                try? await Task.sleep(for: .seconds(2))
            }
        }

        if selectedProvider == .localMLX {
            Task { await MLXModelManager.shared.load() }
        }
    }

    func openAppleIntelligenceSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Siri-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
