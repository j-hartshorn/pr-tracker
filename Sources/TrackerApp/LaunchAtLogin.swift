import Observation
import ServiceManagement

/// Whether macOS opens the app at login. macOS keeps the setting, and the user can change it in System Settings too.
@MainActor @Observable
public final class LaunchAtLogin {
    public private(set) var status = SMAppService.mainApp.status
    /// Why the last change failed, or nil if it worked.
    public private(set) var error: String?

    public init() {}

    public var isEnabled: Bool { status == .enabled }

    public func set(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        reload()
    }

    public func reload() {
        status = SMAppService.mainApp.status
    }
}
