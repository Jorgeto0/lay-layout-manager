import Cocoa

// EnvironmentDetector - Phase 4
// Single responsibility: detect monitor configuration changes
// Notifies delegate when displays connect or disconnect

protocol EnvironmentDetectorDelegate: AnyObject {
    func monitorsDidChange()
}

class EnvironmentDetector {

    weak var delegate: EnvironmentDetectorDelegate?

    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        print("[EnvironmentDetector] Monitoring display changes")
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
        print("[EnvironmentDetector] Stopped monitoring")
    }

    @objc private func screensDidChange() {
        let count = NSScreen.screens.count
        print("[EnvironmentDetector] Display change detected — \(count) screen(s) active")
        delegate?.monitorsDidChange()
    }

    // Returns a hash of the current monitor configuration
    // Used later to match saved layouts to display profiles
    func currentConfigurationHash() -> String {
        let screens = NSScreen.screens.map { screen -> String in
            let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let size = screen.frame.size
            return "\(id)_\(Int(size.width))x\(Int(size.height))"
        }.sorted().joined(separator: "|")

        print("[EnvironmentDetector] Current config: \(screens)")
        return screens
    }
}
