import SwiftUI

@main
struct LayLayoutManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, EnvironmentDetectorDelegate {
    private var statusItem: NSStatusItem?
    private let tracker = WindowTracker()
    private let store = LayoutStore()
    private let restoreEngine = RestoreEngine()
    private let detector = EnvironmentDetector()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Lay Layout Manager")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Lay Layout Manager", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Save Layout", action: #selector(saveLayout), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Restore Layout", action: #selector(restoreLayout), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Start monitoring display changes
        detector.delegate = self
        detector.startMonitoring()

        // Log current display configuration
        _ = detector.currentConfigurationHash()
    }

    // Called automatically when monitors connect or disconnect
    func monitorsDidChange() {
        print("[AppDelegate] Monitor change — waiting 1s for system to settle...")

        // Wait 1 second for macOS to finish reconfiguring displays
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("[AppDelegate] Triggering auto-restore")
            self.restoreLayout()
        }
    }

    @objc func saveLayout() {
        let windows = tracker.getAllWindows()
        store.save(windows: windows)
    }

    @objc func restoreLayout() {
        guard let snapshot = store.load() else {
            print("[AppDelegate] No snapshot to restore")
            return
        }
        restoreEngine.restore(from: snapshot)
    }
}
