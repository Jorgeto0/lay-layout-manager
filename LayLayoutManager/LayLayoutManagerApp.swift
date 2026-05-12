import SwiftUI
import ApplicationServices

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
    private var onboardingWindow: NSWindow?
    private var accessibilityTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Lay Layout Manager")
        }

        statusItem?.menu = buildMenu()

        if AXIsProcessTrusted() {
            startApp()
        } else {
            showOnboarding()
        }
    }

    // Called once Accessibility is granted
    private func startApp() {
        detector.delegate = self
        detector.startMonitoring()
        let config = detector.currentConfigurationHash()
        print("[AppDelegate] Active config: \(config)")
        print("[LoginItemManager] Launch at login: \(loginItemManager.isEnabled)")
    }

    // Show onboarding and poll for permission
    private func showOnboarding() {
        print("[AppDelegate] Accessibility not granted — showing onboarding")

        let view = OnboardingView()
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Lay"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 380, height: 400))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window

        // Poll every 2 seconds until permission is granted
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                print("[AppDelegate] Accessibility granted — starting app")
                timer.invalidate()
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
                self?.startApp()
            }
        }
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
