import Foundation
import FoundationModels
import Testing
@testable import Notypo

private let shouldRunProviderBenchmarks = {
    let environment = ProcessInfo.processInfo.environment["NOTYPO_RUN_PROVIDER_BENCHMARKS"]
    if environment == "1" {
        return true
    }

    let flagFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent(".run-provider-benchmarks")
    if FileManager.default.fileExists(atPath: flagFile.path) {
        return true
    }

    return UserDefaults.standard.bool(forKey: "NOTYPO_RUN_PROVIDER_BENCHMARKS")
}()

struct ProviderBenchmarkTests {

    @Test(
        .enabled(
            if: shouldRunProviderBenchmarks,
            "Set NOTYPO_RUN_PROVIDER_BENCHMARKS=1, the matching test default, or create NotypoTests/.run-provider-benchmarks to run live provider benchmarks."
        )
    )
    @MainActor
    func compareProviders() async throws {
        let runner = ProviderBenchmarkRunner(cases: ProviderBenchmarkCase.all)
        let targets = benchmarkTargets()

        #expect(!targets.isEmpty, "No benchmark providers are available on this machine.")

        let results = try await runner.run(targets: targets)
        let summary = runner.renderSummary(results)
        print(summary)
    }

    @MainActor
    private func benchmarkTargets() -> [ProviderBenchmarkTarget] {
        var targets = [ProviderBenchmarkTarget]()

        if SystemLanguageModel.default.availability == .available {
            targets.append(
                ProviderBenchmarkTarget(name: "Apple Intelligence") {
                    AppleIntelligenceProvider()
                }
            )
        }

        let openAIAPIKey =
            ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ProofreadService.shared.openAIAPIKey
        if !openAIAPIKey.isEmpty {
            let model =
                ProcessInfo.processInfo.environment["NOTYPO_BENCHMARK_OPENAI_MODEL"]
                ?? ProofreadService.shared.openAIModel
            targets.append(
                ProviderBenchmarkTarget(name: "OpenAI (\(model))") {
                    OpenAIProvider(apiKey: openAIAPIKey, model: model)
                }
            )
        }

        for modelID in benchmarkMLXModelIDs() {
            let label = MLXModel.all.first(where: { $0.id == modelID })?.name ?? modelID
            targets.append(
                ProviderBenchmarkTarget(name: "Qwen (\(label))") {
                    let manager = MLXModelManager.shared
                    manager.modelID = modelID
                    await manager.load()

                    guard let provider = manager.makeProvider() else {
                        throw MLXProviderError.modelNotLoaded
                    }

                    return provider
                }
            )
        }

        return targets
    }

    @MainActor
    private func benchmarkMLXModelIDs() -> [String] {
        if let configured = ProcessInfo.processInfo.environment["NOTYPO_BENCHMARK_MLX_MODELS"] {
            return configured
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        let currentModelID = MLXModelManager.shared.modelID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !currentModelID.isEmpty else {
            return []
        }

        return [currentModelID]
    }
}

private struct ProviderBenchmarkTarget {
    let name: String
    let makeProvider: @MainActor () async throws -> any LLMProvider
}

private struct ProviderBenchmarkCase {
    let wrong: String
    let corrected: String
    let note: String

    static let all: [ProviderBenchmarkCase] = [
        .init(
            wrong: "Can yoi sned me thr documrnt?",
            corrected: "Can you send me the document?",
            note: "Adjacent-key typos. Words are gibberish."
        ),
        .init(
            wrong: "She is definittely coming to thee party.",
            corrected: "She is definitely coming to the party.",
            note: "Extra duplicate letters."
        ),
        .init(
            wrong: "I recieved teh package yesterday.",
            corrected: "I received the package yesterday.",
            note: "Transposed letters."
        ),
        .init(
            wrong: "Dont forget to pick up your brothers car.",
            corrected: "Don't forget to pick up your brother's car.",
            note: "Missing apostrophes in a contraction and possessive."
        ),
        .init(
            wrong: "Yesterday I walk to work and seen a bird.",
            corrected: "Yesterday I walked to work and saw a bird.",
            note: "Past-tense agreement."
        ),
        .init(
            wrong: "The whether will effect our plans alot.",
            corrected: "The weather will affect our plans a lot.",
            note: "Three commonly confused words."
        ),
        .init(
            wrong: "Their going to the store over they're.",
            corrected: "They're going to the store over there.",
            note: "Homophones with semantic role changes."
        ),
        .init(
            wrong: "The list of items are on the table.",
            corrected: "The list of items is on the table.",
            note: "Subject-verb agreement through a prepositional phrase."
        ),
        .init(
            wrong: "She is good in math and interested for science.",
            corrected: "She is good at math and interested in science.",
            note: "Wrong prepositions."
        ),
        .init(
            wrong: "I would happy to help you the project.",
            corrected: "I would be happy to help you with the project.",
            note: "Missing words."
        ),
        .init(
            wrong: "I like cooking my family and my pets.",
            corrected: "I like cooking, my family, and my pets.",
            note: "Missing commas alter meaning."
        ),
        .init(
            wrong: "I could of done it if I would of tried.",
            corrected: "I could have done it if I would have tried.",
            note: "Phonetic misspelling from speech."
        ),
        .init(
            wrong: "For all intensive purposes, the project is complete.",
            corrected: "For all intents and purposes, the project is complete.",
            note: "Eggcorn."
        ),
        .init(
            wrong: "Between you and I, this plan is failing.",
            corrected: "Between you and me, this plan is failing.",
            note: "Hypercorrection."
        ),
        .init(
            wrong: "The manager complement on the report that peaked his interest.",
            corrected: "The manager complimented her on the report that piqued his interest.",
            note: "Near-homophones with a missing pronoun."
        ),
        .init(
            wrong: "After finishing the report, the coffee was cold.",
            corrected: "After I finished the report, the coffee was cold.",
            note: "Dangling modifier."
        ),
        .init(
            wrong: "He's a real trooper with deep-seeded beliefs in hard work.",
            corrected: "He's a real trouper with deep-seated beliefs in hard work.",
            note: "Double eggcorn."
        ),
        .init(
            wrong: "I could care less about the results, it's a mute point anyways.",
            corrected: "I couldn't care less about the results; it's a moot point anyway.",
            note: "Idiom errors plus comma splice."
        ),
        .init(
            wrong: "The patient was prescribed a regiment of antibiotics and told to lay down.",
            corrected: "The patient was prescribed a regimen of antibiotics and told to lie down.",
            note: "Malapropism and lay/lie confusion."
        ),
        .init(
            wrong: "I'll be their in a minuet, just need to grab my duck before I loose it.",
            corrected: "I'll be there in a minute, just need to grab my bag before I lose it.",
            note: "Every wrong word is valid English."
        )
    ]
}

private struct ProviderBenchmarkCaseResult {
    let input: String
    let expected: String
    let actual: String
    let latencySeconds: Double
    let exactMatch: Bool
    let similarity: Double
    let note: String
    let errorDescription: String?
}

private struct ProviderBenchmarkResult {
    let providerName: String
    let caseResults: [ProviderBenchmarkCaseResult]

    var exactMatchCount: Int {
        caseResults.filter(\.exactMatch).count
    }

    var averageSimilarity: Double {
        guard !caseResults.isEmpty else { return 0 }
        return caseResults.map(\.similarity).reduce(0, +) / Double(caseResults.count)
    }

    var averageLatencySeconds: Double {
        guard !caseResults.isEmpty else { return 0 }
        return caseResults.map(\.latencySeconds).reduce(0, +) / Double(caseResults.count)
    }
}

@MainActor
private struct ProviderBenchmarkRunner {
    let cases: [ProviderBenchmarkCase]

    func run(targets: [ProviderBenchmarkTarget]) async throws -> [ProviderBenchmarkResult] {
        let session = ProofreadSession(originalText: "")
        var results = [ProviderBenchmarkResult]()

        for target in targets {
            let provider = try await target.makeProvider()
            var caseResults = [ProviderBenchmarkCaseResult]()

            for benchmarkCase in cases {
                let clock = ContinuousClock()
                let start = clock.now

                do {
                    let actual = try await session.proofread(
                        text: benchmarkCase.wrong,
                        toneGuide: "",
                        provider: provider
                    )
                    let latency = durationSeconds(start.duration(to: clock.now))
                    caseResults.append(
                        ProviderBenchmarkCaseResult(
                            input: benchmarkCase.wrong,
                            expected: benchmarkCase.corrected,
                            actual: actual,
                            latencySeconds: latency,
                            exactMatch: normalize(actual) == normalize(benchmarkCase.corrected),
                            similarity: similarityScore(actual, benchmarkCase.corrected),
                            note: benchmarkCase.note,
                            errorDescription: nil
                        )
                    )
                } catch {
                    let latency = durationSeconds(start.duration(to: clock.now))
                    caseResults.append(
                        ProviderBenchmarkCaseResult(
                            input: benchmarkCase.wrong,
                            expected: benchmarkCase.corrected,
                            actual: "",
                            latencySeconds: latency,
                            exactMatch: false,
                            similarity: 0,
                            note: benchmarkCase.note,
                            errorDescription: error.localizedDescription
                        )
                    )
                }
            }

            results.append(
                ProviderBenchmarkResult(providerName: target.name, caseResults: caseResults)
            )
        }

        return results
    }

    func renderSummary(_ results: [ProviderBenchmarkResult]) -> String {
        var lines = ["Provider benchmark summary", ""]
        lines.append("| Provider | Exact Matches | Avg Similarity | Avg Latency |")
        lines.append("| --- | ---: | ---: | ---: |")

        for result in results {
            lines.append(
                "| \(result.providerName) | \(result.exactMatchCount)/\(result.caseResults.count) | \(formatPercent(result.averageSimilarity)) | \(formatDuration(result.averageLatencySeconds)) |"
            )
        }

        for result in results {
            lines.append("")
            lines.append("Failures for \(result.providerName):")

            let failures = result.caseResults.filter { !$0.exactMatch }
            if failures.isEmpty {
                lines.append("- none")
                continue
            }

            for failure in failures {
                lines.append("- input: \(failure.input)")
                lines.append("  expected: \(failure.expected)")
                if let errorDescription = failure.errorDescription {
                    lines.append("  error: \(errorDescription)")
                } else {
                    lines.append("  actual: \(failure.actual)")
                    lines.append("  similarity: \(formatPercent(failure.similarity))")
                }
                lines.append("  note: \(failure.note)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
    }

    private func similarityScore(_ lhs: String, _ rhs: String) -> Double {
        let left = Array(normalize(lhs))
        let right = Array(normalize(rhs))
        let maxLength = max(left.count, right.count)

        guard maxLength > 0 else { return 1 }

        let distance = levenshteinDistance(left, right)
        return 1 - (Double(distance) / Double(maxLength))
    }

    private func levenshteinDistance(_ lhs: [Character], _ rhs: [Character]) -> Int {
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previousRow = Array(0...rhs.count)

        for (leftIndex, leftCharacter) in lhs.enumerated() {
            var currentRow = [leftIndex + 1]

            for (rightIndex, rightCharacter) in rhs.enumerated() {
                let insertion = currentRow[rightIndex] + 1
                let deletion = previousRow[rightIndex + 1] + 1
                let substitution = previousRow[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                currentRow.append(min(insertion, deletion, substitution))
            }

            previousRow = currentRow
        }

        return previousRow[rhs.count]
    }

    private func formatPercent(_ value: Double) -> String {
        let percent = value * 100
        return "\(percent.formatted(.number.precision(.fractionLength(1))))%"
    }

    private func durationSeconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds)
            + (Double(duration.components.attoseconds) / 1_000_000_000_000_000_000)
    }

    private func formatDuration(_ seconds: Double) -> String {
        return "\(seconds.formatted(.number.precision(.fractionLength(2))))s"
    }
}
