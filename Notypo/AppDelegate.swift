import AppKit
import Observation

@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {

    let accessibilityManager = AccessibilityManager()
    private let textRewriter = TextRewriter()
    private var hotkeyMonitor: HotkeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyMonitor = HotkeyMonitor {
            guard let text = await self.textRewriter.readSelection() else { return }
            print("[Notypo] Selected: \(text)")
            await self.textRewriter.replaceSelection(with: "test")
        }

        accessibilityManager.startMonitoring()
    }

    var needsOnboarding: Bool {
        !accessibilityManager.isGranted
    }
}
