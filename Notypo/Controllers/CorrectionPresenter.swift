import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class CorrectionPresenter {

    static let shared = CorrectionPresenter()

    private static let dismissDurationKey = "correctionDismissDuration"

    var dismissDuration: Double = {
        let value = UserDefaults.standard.double(forKey: dismissDurationKey)
        return value > 0 ? value : 5
    }() {
        didSet { UserDefaults.standard.set(dismissDuration, forKey: Self.dismissDurationKey) }
    }

    private let gap: CGFloat = 16
    private let padding: CGFloat = 8

    private var panel: NSPanel?
    private var dismissTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private var keyMonitor: Any? {
        didSet {
            if let oldValue {
                NSEvent.removeMonitor(oldValue)
            }
        }
    }

    private init() {}

    // MARK: - Public

    func show(before: String, after: String) {
        dismiss()

        let segments = DiffSegment.wordDiff(original: before, corrected: after)
        guard !segments.isEmpty else { return }

        let panel = makePanel(segments: segments)
        let anchor = Self.caretRect() ?? Self.mouseRect()
        panel.setFrameOrigin(position(panelSize: panel.frame.size, below: anchor))

        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }

        self.panel = panel
        scheduleDismiss()
    }

    func dismiss() {
        dismissTask = nil
        keyMonitor = nil

        guard let panel else { return }
        let panelRef = panel
        self.panel = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panelRef.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in panelRef.orderOut(nil) }
        }
    }

    // MARK: - Private

    private func makePanel(segments: [DiffSegment]) -> NSPanel {
        let maxWidth: CGFloat = 400

        let hosting = NSHostingView(
            rootView: CorrectionView(segments: segments)
                .frame(maxWidth: maxWidth)
        )

        let unconstrained = hosting.fittingSize
        let width = min(unconstrained.width, maxWidth)
        hosting.frame.size.width = width
        hosting.layoutSubtreeIfNeeded()
        let height = hosting.fittingSize.height
        let size = NSSize(width: width, height: height)
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.contentView = hosting
        panel.setContentSize(size)
        return panel
    }

    private func scheduleDismiss() {
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(self.dismissDuration))
            dismiss()
        }
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            Task { @MainActor in self?.dismiss() }
        }
    }

    private static func caretRect() -> NSRect? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success else {
            return nil
        }
        guard let focusedRef else { return nil }
        let focused = focusedRef as! AXUIElement

        var rangeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
              let range = rangeRef else {
            return nil
        }

        var boundsRef: AnyObject?
        guard AXUIElementCopyParameterizedAttributeValue(
            focused,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            range,
            &boundsRef
        ) == .success else {
            return nil
        }

        var axRect = CGRect.zero
        guard let boundsRef,
              AXValueGetValue(boundsRef as! AXValue, .cgRect, &axRect) else {
            return nil
        }

        // AX uses top-left origin; convert to AppKit bottom-left origin
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        return NSRect(
            x: axRect.origin.x,
            y: screenHeight - axRect.origin.y - axRect.height,
            width: axRect.width,
            height: axRect.height
        )
    }

    private static func mouseRect() -> NSRect {
        let mouse = NSEvent.mouseLocation
        return NSRect(x: mouse.x, y: mouse.y, width: 0, height: 0)
    }

    private func position(panelSize: NSSize, below anchor: NSRect) -> NSPoint {
        let screen = NSScreen.screens.first(where: {
            NSPointInRect(NSPoint(x: anchor.midX, y: anchor.midY), $0.frame)
        })?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        // Below the anchor, center-aligned
        var x = anchor.midX - panelSize.width / 2
        var y = anchor.minY - gap - panelSize.height

        // If not enough space below, show above
        if y < screen.minY + padding {
            y = anchor.maxY + gap
        }

        // Keep on screen
        x = min(max(x, screen.minX + padding), screen.maxX - panelSize.width - padding)
        y = min(max(y, screen.minY + padding), screen.maxY - panelSize.height - padding)

        return NSPoint(x: x, y: y)
    }
}
