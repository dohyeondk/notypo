import AppKit

extension NSApplication {
    func show() {
        setActivationPolicy(.regular)
        activate(ignoringOtherApps: true)
    }

    func hide() {
        hide(self)
        setActivationPolicy(.accessory)
    }
}
