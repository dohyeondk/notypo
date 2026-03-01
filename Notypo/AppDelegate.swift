import AppKit
import Observation

@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[Notypo] App launched")
    }
}
