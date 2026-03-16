import AIProxy
import Foundation

struct OpenAIProvider: LLMProvider {

    let apiKey: String
    let model: String

    func proofread(text: String, systemPrompt: String) async throws -> String {
        let service = AIProxy.openAIDirectService(unprotectedAPIKey: apiKey)

        let requestBody = OpenAIChatCompletionRequestBody(
            model: model,
            messages: [
                .system(content: .text(systemPrompt)),
                .user(content: .text("\"\(text)\""))
            ]
        )

        let response = try await service.chatCompletionRequest(body: requestBody, secondsToWait: 60)

        guard let content = response.choices.first?.message.content else {
            throw OpenAIProviderError.unexpectedResponse
        }

        return content
    }
}

enum OpenAIProviderError: LocalizedError {
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            "Unexpected response from OpenAI."
        }
    }
}
