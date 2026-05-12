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
    private let reconciler = ReconciliationEngine()
    private let detector = EnvironmentDetector()
    private let loginItemManager = LoginItemManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Lay Layout Manager")
        }

        statusItem?.menu = buildMenu()

        detector.delegate = self
        detector.startMonitoring()

        let config = detector.currentConfigurationHash()
        print("[AppDelegate] Active config: \(config)")
        print("[LoginItemManager] Launch at login: \(loginItemManager.isEnabled)")
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Lay Layout Manager", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Save Layout", action: #selector(saveLayout), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Restore Layout", action: #selector(restoreLayout), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "[DEV] Simulate Monitor Change", action: #selector(simulateMonitorChange), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    func monitorsDidChange() {
        print("[AppDelegate] Monitor change — waiting 1s for system to settle...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("[AppDelegate] Triggering auto-restore")
            self.restoreAndVerify()
        }
    }

    @objc func simulateMonitorChange() {
        print("[AppDelegate] Simulating monitor change")
        monitorsDidChange()
    }

    @objc func saveLayout() {
        let config = detector.currentConfigurationHash()
        let windows = tracker.getAllWindows()
        store.save(windows: windows, configHash: config)
    }

    @objc func restoreLayout() {
        restoreAndVerify()
    }

    @objc func toggleLoginItem() {
        loginItemManager.toggle()
        statusItem?.menu = buildMenu()
        print("[AppDelegate] Launch at login: \(loginItemManager.isEnabled)")
    }

    private func restoreAndVerify() {
        let config = detector.currentConfigurationHash()
        guard let snapshot = store.load(configHash: config) else {
            print("[AppDelegate] No snapshot for current config: \(config)")
            return
        }
        restoreEngine.restore(from: snapshot)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.reconciler.verify(snapshot: snapshot)
        }
    }
}
