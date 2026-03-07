import FoundationModels
import Testing
@testable import Notypo

struct ProofreadSessionTests {

    @Test(
        .enabled(
            if: SystemLanguageModel.default.availability == .available,
            "Apple Intelligence is unavailable on this machine."
        )
    )
    func proofread() async throws {
        let attempts = 100
        var exactMatches = 0
        let session = await MainActor.run { ProofreadSession(originalText: "") }

        for _ in 0..<attempts {
            if let result = try? await session.proofread(text: "Proofread", toneGuide: ""),
               result == "Proofread" {
                exactMatches += 1
            }
        }
        
        #expect(
            exactMatches >= 90,
            "Expected at least 90 exact matches out of \(attempts), got \(exactMatches)."
        )
    }
}
