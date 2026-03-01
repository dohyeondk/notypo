import KeyboardShortcuts
import Observation

@MainActor
@Observable
final class AppState {

    var needsOnboarding: Bool {
        !AccessibilityManager.shared.isGranted || ProofreadService.shared.availability != .available
    }

    init() {
        start()
    }

    private func start() {
        AccessibilityManager.shared.startMonitoring()
        ProofreadService.shared.startMonitoring()

        KeyboardShortcuts.onKeyDown(for: .proofread) { [weak self] in
            guard let self else { return }
            Task { @MainActor in await self.handleHotkey() }
        }
    }

    func handleHotkey() async {
        let proofreadService = ProofreadService.shared
        guard !proofreadService.isProcessing else { return }
        guard proofreadService.availability == .available else { return }
        guard let text = await TextRewriter.shared.readSelection() else { return }

        proofreadService.isProcessing = true
        defer { proofreadService.isProcessing = false }

        do {
            let corrected = try await proofreadService.proofread(text)
            guard corrected != text else { return }
            await TextRewriter.shared.replaceSelection(with: corrected)
            CorrectionPresenter.shared.show(before: text, after: corrected)
        } catch {
            print("[Notypo] Proofread error: \(error)")
        }
    }
}
