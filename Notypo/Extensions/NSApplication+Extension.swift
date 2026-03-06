import AppKit

extension NSApplication {
    func show() {
        setActivationPolicy(.regular)
        activate(ignoringOtherApps: true)
    }

    func hide() {
        setActivationPolicy(.accessory)
    }
}
