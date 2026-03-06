import AppKit

@MainActor
final class TextRewriter {

    static let shared = TextRewriter()

    private let pasteboard = NSPasteboard.general
    private let delay: UInt64 = 100_000_000 // 100ms in nanoseconds

    func readSelection() async -> String? {
        let previousChangeCount = pasteboard.changeCount

        simulateKeyPress(key: 0x08, flags: .maskCommand) // ⌘C
        try? await Task.sleep(nanoseconds: delay)

        guard pasteboard.changeCount != previousChangeCount,
              let text = pasteboard.string(forType: .string)
        else {
            return nil
        }

        return text
    }

    func replaceSelection(with text: String) async {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        simulateKeyPress(key: 0x09, flags: .maskCommand) // ⌘V
        try? await Task.sleep(nanoseconds: delay)
    }

    private func simulateKeyPress(key: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}
