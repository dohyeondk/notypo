import KeyboardShortcuts
import Observation
import SwiftUI

@MainActor
@Observable
final class AppState {

    var needsOnboarding: Bool {
        !AccessibilityManager.shared.isGranted || ProofreadService.shared.availability != .available
    }

    private(set) var currentSession: ProofreadSession?

    var isRunning: Bool {
        currentSession?.isProcessing == true
    }

    init() {
        start()
    }

    private func start() {
        AccessibilityManager.shared.startMonitoring()
        ProofreadService.shared.startMonitoring()

        KeyboardShortcuts.onKeyDown(for: .hotkey) { [weak self] in
            guard let self else { return }
            Task { @MainActor in await self.handleHotkey() }
        }
    }

    func handleHotkey() async {
        guard ProofreadService.shared.availability == .available else { return }
        guard let text = await TextRewriter.shared.readSelection() else { return }

        let session = ProofreadSession(originalText: text)
        currentSession = session

        session.onDiscard = { [weak self] in
            self?.currentSession = nil
        }

        session.onApply = { [weak self] corrected in
            self?.currentSession = nil
            Task { @MainActor in
                await TextRewriter.shared.replaceSelection(with: corrected)
            }
        }
    }
}
