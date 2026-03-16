import FoundationModels

struct AppleIntelligenceProvider: LLMProvider {

    func proofread(text: String, systemPrompt: String) async throws -> String {
        let session = LanguageModelSession { systemPrompt }
        let response = try await session.respond(to: "\"\(text)\"")
        return response.content
    }
}
