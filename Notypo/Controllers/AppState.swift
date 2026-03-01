import KeyboardShortcuts
import Observation

@MainActor
@Observable
final class AppState {

    let accessibilityManager = AccessibilityManager()
    let proofreadService = ProofreadService()

    private let textRewriter = TextRewriter()

    var needsOnboarding: Bool {
        !accessibilityManager.isGranted || proofreadService.availability != .available
    }

    init() {
        start()
    }

    private func start() {
        accessibilityManager.startMonitoring()
        proofreadService.startMonitoring()

        KeyboardShortcuts.onKeyDown(for: .proofread) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.handleHotkey()
            }
        }
    }

    func handleHotkey() async {
        guard !proofreadService.isProcessing else { return }
        guard proofreadService.availability == .available else { return }
        guard let text = await textRewriter.readSelection() else { return }

        proofreadService.isProcessing = true
        defer { proofreadService.isProcessing = false }

        do {
            let corrected = try await proofreadService.proofread(text)
            guard corrected != text else { return }
            await textRewriter.replaceSelection(with: corrected)
            CorrectionPresenter.shared.show(before: text, after: corrected)
        } catch {
            print("[Notypo] Proofread error: \(error)")
        }
    }
}
