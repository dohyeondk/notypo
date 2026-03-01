import AppKit
import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class ProofreadService {

    static let shared = ProofreadService()

    var availability: SystemLanguageModel.Availability = SystemLanguageModel.default.availability
    var isProcessing: Bool = false

    private static let toneGuideKey = "toneGuide"

    var toneGuide: String = UserDefaults.standard.string(forKey: toneGuideKey) ?? "" {
        didSet { UserDefaults.standard.set(toneGuide, forKey: Self.toneGuideKey) }
    }

    private var pollingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    func startMonitoring() {
        pollingTask = Task {
            while !Task.isCancelled {
                availability = SystemLanguageModel.default.availability
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func openAppleIntelligenceSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Siri-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func proofread(_ text: String) async throws -> String {
        var systemPrompt = """
            You are a proofreading assistant. \
            Fix typos, spelling errors, and grammar mistakes in the user's text. \
            Preserve the original tone, formatting, capitalization style, and punctuation style. \
            Do NOT add explanations, comments, or quotation marks. \
            Return ONLY the corrected text.
            """

        if !toneGuide.isEmpty {
            systemPrompt += "\nTone guide: \(toneGuide)"
        }

        let session = LanguageModelSession { systemPrompt }
        let response = try await session.respond(to: text)
        return response.content
    }
}
