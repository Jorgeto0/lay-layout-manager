import ServiceManagement

// LoginItemManager - Phase 7
// Single responsibility: register and unregister the app as a login item
// Uses SMAppService — the modern API for launch at login (macOS 13+)

class LoginItemManager {

    private let service = SMAppService.mainApp

    var isEnabled: Bool {
        service.status == .enabled
    }

    func enable() {
        do {
            try service.register()
            print("[LoginItemManager] Launch at login enabled")
        } catch {
            print("[LoginItemManager] ERROR enabling login item: \(error)")
        }
    }

    func disable() {
        do {
            try service.unregister()
            print("[LoginItemManager] Launch at login disabled")
        } catch {
            print("[LoginItemManager] ERROR disabling login item: \(error)")
        }
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }
}
