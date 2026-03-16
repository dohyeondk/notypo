import Foundation
import MLXLMCommon
import MLXLLM

enum MLXProviderError: LocalizedError {
    case modelNotLoaded
    case outputLimitReached
    case finalResponseMissing

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "Local model failed to load."
        case .outputLimitReached:
            "Local model did not finish proofreading within the output limit."
        case .finalResponseMissing:
            "Local model returned reasoning without a final proofreading result."
        }
    }
}

struct MLXProvider: LLMProvider {

    private static let finalResponseOpenTag = "<final>"
    private static let finalResponseCloseTag = "</final>"

    let modelContainer: ModelContainer

    func proofread(text: String, systemPrompt: String) async throws -> String {
        let wrappedSystemPrompt = """
            \(systemPrompt)
            You may reason privately if needed, but your visible reply must contain the final
            corrected text exactly once between \(Self.finalResponseOpenTag) and
            \(Self.finalResponseCloseTag).
            Do not put labels, bullet points, or explanations inside
            \(Self.finalResponseOpenTag) and \(Self.finalResponseCloseTag).
            """

        let input = try await modelContainer.prepare(
            input: UserInput(chat: [
                .system(wrappedSystemPrompt),
                .user("\"\(text)\"")
            ])
        )

        let parameters = GenerateParameters(
            maxTokens: Self.maxOutputTokens(for: text),
            temperature: 0.0
        )
        let stream = try await modelContainer.generate(input: input, parameters: parameters)

        var result = ""
        var completionInfo: GenerateCompletionInfo?
        for await part in stream {
            switch part {
            case .chunk(let chunk):
                result += chunk
            case .info(let info):
                completionInfo = info
            case .toolCall:
                break
            }
        }

        if completionInfo?.stopReason == .length {
            throw MLXProviderError.outputLimitReached
        }

        return try Self.extractVisibleResponse(from: result)
    }

    static func maxOutputTokens(for text: String) -> Int {
        let characterCount = text.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count
        let estimatedTokenBudget = ((characterCount / 2) + 48) * 2
        return min(1024, max(160, estimatedTokenBudget))
    }

    static func extractVisibleResponse(from text: String) throws -> String {
        if let taggedResponse = extractTaggedContent(
            in: text,
            openTag: finalResponseOpenTag,
            closeTag: finalResponseCloseTag
        ) {
            return taggedResponse
        }

        let withoutThinkTags = stripTaggedSections(
            in: text,
            openTag: "<think>",
            closeTag: "</think>"
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        if let taggedResponse = extractTaggedContent(
            in: withoutThinkTags,
            openTag: finalResponseOpenTag,
            closeTag: finalResponseCloseTag
        ) {
            return taggedResponse
        }

        if let labeledResponse = extractLabeledResponse(from: withoutThinkTags) {
            return labeledResponse
        }

        let normalized = withoutThinkTags.lowercased()
        if normalized.contains("thinking process:")
            || normalized.hasPrefix("reasoning:")
            || normalized.hasPrefix("analysis:") {
            throw MLXProviderError.finalResponseMissing
        }

        let cleaned = withoutThinkTags.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw MLXProviderError.finalResponseMissing
        }

        return cleaned
    }

    private static func extractTaggedContent(
        in text: String,
        openTag: String,
        closeTag: String
    ) -> String? {
        guard let openRange = text.range(of: openTag, options: .backwards),
              let closeRange = text.range(of: closeTag, range: openRange.upperBound..<text.endIndex)
        else {
            return nil
        }

        let content = text[openRange.upperBound..<closeRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? nil : String(content)
    }

    private static func stripTaggedSections(
        in text: String,
        openTag: String,
        closeTag: String
    ) -> String {
        var remaining = text

        while let openRange = remaining.range(of: openTag),
              let closeRange = remaining.range(
                of: closeTag,
                range: openRange.upperBound..<remaining.endIndex
              ) {
            remaining.removeSubrange(openRange.lowerBound..<closeRange.upperBound)
        }

        return remaining
    }

    private static func extractLabeledResponse(from text: String) -> String? {
        let markers = [
            "Final answer:",
            "Final response:",
            "Corrected text:",
            "Response:"
        ]

        for marker in markers {
            guard let markerRange = text.range(of: marker, options: [.caseInsensitive, .backwards]) else {
                continue
            }

            let content = text[markerRange.upperBound...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                return String(content)
            }
        }

        return nil
    }
}
