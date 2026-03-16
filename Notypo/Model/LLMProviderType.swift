enum LLMProviderType: String, CaseIterable, Identifiable {
    case appleIntelligence
    case openAI
    case localMLX

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .openAI: "OpenAI"
        case .localMLX: "Local (MLX)"
        }
    }
}
