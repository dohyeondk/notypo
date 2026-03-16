struct MLXModel: Identifiable {
    let id: String
    let name: String
    let size: String
    let isExperimental: Bool

    static let all: [MLXModel] = [
        MLXModel(
            id: "mlx-community/Qwen2.5-3B-Instruct-4bit",
            name: "Qwen 2.5 3B",
            size: "~1.9 GB",
            isExperimental: false
        ),
        MLXModel(
            id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            name: "Qwen 2.5 1.5B",
            size: "~1.0 GB",
            isExperimental: false
        ),
        MLXModel(
            id: "mlx-community/Qwen2.5-7B-Instruct-4bit",
            name: "Qwen 2.5 7B",
            size: "~4.4 GB",
            isExperimental: false
        ),
        MLXModel(
            id: "mlx-community/Qwen3.5-4B-MLX-4bit",
            name: "Qwen 3.5 4B",
            size: "~2.5 GB",
            isExperimental: true
        ),
        MLXModel(
            id: "mlx-community/Qwen3.5-9B-MLX-4bit",
            name: "Qwen 3.5 9B",
            size: "~5.5 GB",
            isExperimental: true
        )
    ]
}
