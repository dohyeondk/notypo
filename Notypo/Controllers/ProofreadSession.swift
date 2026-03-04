import FoundationModels
import Observation
import SwiftUI

@MainActor
@Observable
class ProofreadSession {

    enum Phase: Equatable {
        case ready
        case processing
        case succeeded(corrected: String)
        case failed
    }

    let originalText: String
    
    var phase: Phase = .ready

    var isProcessing: Bool { phase == .ready || phase == .processing }
    
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
        guard phase != .processing else {
            return
        }
        
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
        let draft = try await session.respond(to: text)

        let validated = try await session.respond(to: """
            The following is your previous response. It may contain extra text \
            like "Here is the corrected text:" or other commentary. \
            Return ONLY the corrected text with absolutely nothing else. \
            No prefixes, no labels, no explanations.

            \(draft.content)
            """)
        return validated.content
    }
}
