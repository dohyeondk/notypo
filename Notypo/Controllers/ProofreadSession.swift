import FoundationModels
import Observation
import SwiftUI

@MainActor
@Observable
class ProofreadSession {

    enum Phase: Equatable {
        case processing
        case succeeded(corrected: String)
        case failed
    }

    let originalText: String
    var phase: Phase = .processing

    var isProcessing: Bool { phase == .processing }
    var isPerfect: Bool {
        if case .succeeded(let corrected) = phase { corrected == originalText } else { false }
    }

    var attributedText: AttributedString {
        let corrected = if case .succeeded(let corrected) = phase { corrected } else { originalText }
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
            phase = .succeeded(corrected: corrected)
        } catch {
            phase = .failed
        }
    }

    private static func proofread(_ text: String, toneGuide: String) async throws -> String {
        var systemPrompt = """
            You are a proofreading assistant. \
            Fix typos, spelling errors, and grammar mistakes in the user's text. \
            Preserve the original tone, formatting, capitalization style, and punctuation style. \
            Preserve all leading and trailing whitespace, newlines, and indentation exactly as given. \
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
