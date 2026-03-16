protocol LLMProvider: Sendable {
    func proofread(text: String, systemPrompt: String) async throws -> String
}
