import AppKit
import SwiftUI

/// A borderless, floating panel that displays a SwiftUI view.
///
/// Use a floating panel to present transient content above other windows
/// without activating the app. The panel accepts keyboard input and
/// sizes itself to fit the provided view.
///
/// ```swift
/// let panel = Panel(MyView())
/// panel.show()
/// ```
class Panel: NSPanel {

    override var canBecomeKey: Bool { true }

    /// Creates a floating panel with the given SwiftUI view as its content.
    ///
    /// - Parameter content: The view to display inside the panel.
    init<Content: View>(_ content: Content) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .normal
        isOpaque = false
        backgroundColor = .clear

        let hosting = NSHostingView(rootView: content)
        hosting.layoutSubtreeIfNeeded()
        contentView = hosting
        setContentSize(hosting.fittingSize)
    }

    /// Centers the panel on screen and makes it the key window.
    func show() {
        center()
        makeKeyAndOrderFront(nil)
    }

    /// Removes the panel from the screen.
    func hide() {
        orderOut(nil)
    }
}
