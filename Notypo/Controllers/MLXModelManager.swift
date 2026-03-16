import Foundation
import MLXLMCommon
import MLXLLM
import Observation

@MainActor
@Observable
final class MLXModelManager {

    static let shared = MLXModelManager()

    struct DownloadProgress: Equatable {
        var fraction: Double
        var filesCompleted: Int64
        var filesTotal: Int64
        var bytesPerSecond: Double
    }

    enum Status: Equatable {
        case idle
        case downloading(DownloadProgress)
        case loading
        case ready
        case failed(message: String)
    }

    private(set) var status: Status = .idle

    var isReady: Bool { status == .ready }

    private var modelContainer: ModelContainer?
    private var loadTask: Task<ModelContainer, Error>?
    private var activeLoadID = UUID()

    private static let modelIDKey = "mlxModelID"
    private static let defaultModelID = "mlx-community/Qwen2.5-3B-Instruct-4bit"

    var modelID: String = UserDefaults.standard.string(forKey: modelIDKey) ?? defaultModelID {
        didSet {
            UserDefaults.standard.set(modelID, forKey: Self.modelIDKey)
            unload()
        }
    }

    func load() async {
        if modelContainer != nil {
            status = .ready
            return
        }

        if let loadTask {
            await awaitLoadTask(loadTask, loadID: activeLoadID)
            return
        }

        let trimmedModelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModelID.isEmpty else {
            status = .failed(message: "Enter a Hugging Face model ID before loading a local model.")
            return
        }

        let loadID = UUID()
        activeLoadID = loadID
        status = .downloading(DownloadProgress(
            fraction: 0, filesCompleted: 0, filesTotal: 0, bytesPerSecond: 0
        ))

        let configuration = LLMModelFactory.shared.configuration(id: trimmedModelID)
        let task = Task<ModelContainer, Error> {
            try await LLMModelFactory.shared.loadContainer(
                configuration: configuration,
                progressHandler: { progress in
                    Task { @MainActor in
                        MLXModelManager.shared.updateProgress(progress, loadID: loadID)
                    }
                }
            )
        }

        loadTask = task
        await awaitLoadTask(task, loadID: loadID)
    }

    func cancel() {
        activeLoadID = UUID()
        loadTask?.cancel()
        loadTask = nil
        status = .idle
    }

    func unload() {
        cancel()
        modelContainer = nil
        status = .idle
    }

    func makeProvider() -> MLXProvider? {
        guard let modelContainer else { return nil }
        return MLXProvider(modelContainer: modelContainer)
    }

    private func awaitLoadTask(_ task: Task<ModelContainer, Error>, loadID: UUID) async {
        do {
            let container = try await task.value
            guard activeLoadID == loadID else { return }

            modelContainer = container
            status = .ready
        } catch is CancellationError {
            guard activeLoadID == loadID else { return }
            status = .idle
        } catch {
            guard activeLoadID == loadID else { return }
            status = .failed(message: error.localizedDescription)
        }

        if activeLoadID == loadID {
            loadTask = nil
        }
    }

    private func updateProgress(_ progress: Progress, loadID: UUID) {
        guard activeLoadID == loadID else { return }

        let fraction = progress.fractionCompleted
        let speed = (progress.userInfo[.throughputKey] as? Double) ?? 0

        if fraction < 1.0 {
            status = .downloading(DownloadProgress(
                fraction: fraction,
                filesCompleted: progress.completedUnitCount,
                filesTotal: progress.totalUnitCount,
                bytesPerSecond: speed
            ))
        } else {
            status = .loading
        }
    }
}
