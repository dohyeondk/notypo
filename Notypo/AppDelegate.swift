import AppKit
import Observation

@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {

    let accessibilityManager = AccessibilityManager()
    let proofreadService = ProofreadService()
    private let textRewriter = TextRewriter()
    private var hotkeyMonitor: HotkeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyMonitor = HotkeyMonitor { [self] in
            await handleHotkey()
        }

        accessibilityManager.startMonitoring()
        proofreadService.startMonitoring()
    }

    private func handleHotkey() async {
        guard !proofreadService.isProcessing else { return }
        guard proofreadService.availability == .available else { return }
        guard let text = await textRewriter.readSelection() else { return }

        proofreadService.isProcessing = true
        defer { proofreadService.isProcessing = false }

        do {
            let corrected = try await proofreadService.proofread(text)
            guard corrected != text else { return }
            await textRewriter.replaceSelection(with: corrected)
        } catch {
            print("[Notypo] Proofread error: \(error)")
        }
    }

    var needsOnboarding: Bool {
        !accessibilityManager.isGranted
    }
}
