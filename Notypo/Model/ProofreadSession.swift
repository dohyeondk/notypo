import FoundationModels
import Observation
import SwiftUI

@MainActor
@Observable
class ProofreadSession {

    enum Phase: Equatable {
        case processing
        case result(corrected: String)
    }

    let originalText: String
    var phase: Phase = .processing

    var isProcessing: Bool { phase == .processing }

    var attributedText: AttributedString {
        let corrected = if case .result(let corrected) = phase { corrected } else { originalText }
        let segments = DiffSegment.wordDiff(original: originalText, corrected: corrected)
        return DiffSegment.attributedString(from: segments)
    }

    var onDiscard: (() -> Void)?
    var onApply: ((String) -> Void)?

    init(originalText: String) {
        self.originalText = originalText
    }

    func run() async {
        phase = .processing

        let text = originalText
        let toneGuide = ProofreadService.shared.toneGuide

        do {
            let corrected = try await Task.detached {
                try await Self.proofread(text, toneGuide: toneGuide)
            }.value
            phase = .result(corrected: corrected)
        } catch {
            print("[Notypo] Proofread error: \(error)")
            onDiscard?()
        }
    }

    private static func proofread(_ text: String, toneGuide: String) async throws -> String {
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
