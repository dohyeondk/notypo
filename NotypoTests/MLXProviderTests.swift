import Testing
@testable import Notypo

struct MLXProviderTests {

    @Test func shortTextUsesMinimumTokenBudget() {
        #expect(MLXProvider.maxOutputTokens(for: "Fix teh typo.") == 160)
    }

    @Test func surroundingWhitespaceDoesNotIncreaseTokenBudget() {
        let compact = MLXProvider.maxOutputTokens(for: "hello")
        let padded = MLXProvider.maxOutputTokens(for: "   hello   \n")

        #expect(compact == padded)
    }

    @Test func tokenBudgetScalesWithInputLength() {
        let short = MLXProvider.maxOutputTokens(for: "Short sentence.")
        let medium = MLXProvider.maxOutputTokens(
            for: String(repeating: "Proofread this sentence carefully. ", count: 8)
        )

        #expect(medium > short)
    }

    @Test func tokenBudgetCapsForVeryLongSelections() {
        let long = MLXProvider.maxOutputTokens(
            for: String(repeating: "Proofread this sentence carefully. ", count: 200)
        )

        #expect(long == 1024)
    }

    @Test func extractsTaggedFinalResponse() throws {
        let raw = """
            Thinking Process:
            1. Analyze the request.

            <final>"Fixed typo."</final>
            """

        #expect(try MLXProvider.extractVisibleResponse(from: raw) == "\"Fixed typo.\"")
    }

    @Test func stripsThinkTagsWhenFinalTextIsBare() throws {
        let raw = """
            <think>
            Evaluate the grammar carefully.
            </think>
            "Fixed typo."
            """

        #expect(try MLXProvider.extractVisibleResponse(from: raw) == "\"Fixed typo.\"")
    }

    @Test func throwsWhenOnlyReasoningIsReturned() {
        let raw = """
            Thinking Process:
            1. Analyze the request.
            2. Decide what to fix.
            """

        do {
            _ = try MLXProvider.extractVisibleResponse(from: raw)
            Issue.record("Expected reasoning-only output to be rejected.")
        } catch let error as MLXProviderError {
            #expect(error.errorDescription == MLXProviderError.finalResponseMissing.errorDescription)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
