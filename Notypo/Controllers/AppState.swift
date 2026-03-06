import AppKit
import KeyboardShortcuts
import Observation
import SwiftUI

@MainActor
@Observable
final class AppState {

    private var needsOnboarding: Bool {
        !AccessibilityManager.shared.isGranted || ProofreadService.shared.availability != .available
    }

    private var proofreadPanel: Panel?
    private var onboardingPanel: Panel?

    private var currentSession: ProofreadSession? {
        didSet {
            proofreadPanel?.hide()
            if let currentSession {
                let newPanel = Panel(ProofreadView(session: currentSession), level: .floating)
                newPanel.show()
                proofreadPanel = newPanel
            } else {
                proofreadPanel = nil
            }
        }
    }

    var isRunning: Bool {
        currentSession?.isProcessing == true
    }

    init() {
        start()
        if needsOnboarding {
            showOnboarding()
        }
    }

    private func start() {
        AccessibilityManager.shared.startMonitoring()
        ProofreadService.shared.startMonitoring()

        KeyboardShortcuts.onKeyDown(for: .proofread) { [weak self] in
            guard let self else { return }
            Task { @MainActor in await self.handleHotkey() }
        }
    }

    private func showOnboarding() {
        onboardingPanel?.hide()
        let view = OnboardingView {
            self.onboardingPanel?.hide()
            self.onboardingPanel = nil
            NSApp.hide()
        }
        .environment(AccessibilityManager.shared)
        .environment(ProofreadService.shared)

        let newPanel = Panel(view)
        newPanel.show()
        NSApp.show()
        onboardingPanel = newPanel
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
