import AppKit
import Observation

@MainActor
@Observable
final class AccessibilityManager {

    static let shared = AccessibilityManager()

    static let permissionDidChange = Notification.Name("AccessibilityPermissionDidChange")

    private(set) var isGranted: Bool = AXIsProcessTrusted() {
        didSet {
            guard isGranted != oldValue else { return }
            NotificationCenter.default.post(name: Self.permissionDidChange, object: self)
        }
    }

    private var pollingTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }

    func startMonitoring() {
        pollingTask = Task {
            while !Task.isCancelled {
                isGranted = AXIsProcessTrusted()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func requestPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
