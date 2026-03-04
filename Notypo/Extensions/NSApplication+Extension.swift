import AppKit

extension NSApplication {
    func show() {
        setActivationPolicy(.accessory)
        activate(ignoringOtherApps: true)
    }

    func hide() {
        hide(self)
        setActivationPolicy(.prohibited)
    }
}
