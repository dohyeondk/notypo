import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchManager {

    static let shared = LaunchManager()

    var isEnabled: Bool = SMAppService.mainApp.status == .enabled {
        didSet {
            guard isEnabled != (SMAppService.mainApp.status == .enabled) else { return }
            if isEnabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
}
