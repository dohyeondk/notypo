import AppKit
import Observation

@MainActor
@Observable
final class HotkeyMonitor {

    private static let storageKey = "hotkeyCombo"

    private var monitor: Any? {
        didSet {
            if let oldValue {
                NSEvent.removeMonitor(oldValue)
            }
        }
    }
    
    private var action: @MainActor () async -> Void

    var keyCombo: KeyCombo {
        didSet {
            save()
            start()
        }
    }

    init(action: @MainActor @escaping () async -> Void) {
        self.action = action
        self.keyCombo = Self.load() ?? KeyCombo(keyCode: 49, modifiers: [.control]) // ⌃Space

        NotificationCenter.default.addObserver(forName: AccessibilityManager.permissionDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.start() }
        }
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            guard event.keyCode == keyCombo.keyCode,
                  event.modifierFlags.contains(keyCombo.modifierFlags)
            else { return }

            Task { await self.action() }
        }
    }

    func stop() {
        monitor = nil
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(keyCombo) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func load() -> KeyCombo? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(KeyCombo.self, from: data)
    }
}
