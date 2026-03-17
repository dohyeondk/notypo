struct OpenAIModel: Identifiable {
    let id: String
    let name: String
    let inputPrice: String
    let outputPrice: String

    static let all: [OpenAIModel] = [
        OpenAIModel(id: "gpt-5.4-mini", name: "GPT-5.4 mini", inputPrice: "$0.75", outputPrice: "$4.50"),
        OpenAIModel(id: "gpt-5.4-nano", name: "GPT-5.4 nano", inputPrice: "$0.20", outputPrice: "$1.25"),
        OpenAIModel(id: "gpt-5.2", name: "GPT-5.2", inputPrice: "$1.75", outputPrice: "$14.00"),
        OpenAIModel(id: "gpt-5.1", name: "GPT-5.1", inputPrice: "$1.25", outputPrice: "$10.00"),
        OpenAIModel(id: "gpt-5", name: "GPT-5", inputPrice: "$1.25", outputPrice: "$10.00"),
        OpenAIModel(id: "gpt-5-mini", name: "GPT-5 mini", inputPrice: "$0.25", outputPrice: "$2.00"),
        OpenAIModel(id: "gpt-5-nano", name: "GPT-5 nano", inputPrice: "$0.05", outputPrice: "$0.40"),
        OpenAIModel(id: "gpt-4.1", name: "GPT-4.1", inputPrice: "$3.00", outputPrice: "$12.00"),
        OpenAIModel(id: "gpt-4.1-mini", name: "GPT-4.1 mini", inputPrice: "$0.80", outputPrice: "$3.20"),
        OpenAIModel(id: "gpt-4.1-nano", name: "GPT-4.1 nano", inputPrice: "$0.20", outputPrice: "$0.80"),
    ]
}
