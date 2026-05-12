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
    private var settingsWindow: NSWindow?
    private var accessibilityTimer: Timer?
    private var lastSaveDate: Date?
    private var windowCount: Int = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            // Use our app icon as menu bar icon template
            if let icon = NSImage(named: "AppIcon") {
                let resized = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                    icon.draw(in: rect)
                    return true
                }
                resized.isTemplate = false
                button.image = resized
            } else {
                button.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Lay")
            }
        }

        statusItem?.menu = buildMenu()

        if AXIsProcessTrusted() {
            startApp()
        } else {
            showOnboarding()
        }
    }

    private func startApp() {
        detector.delegate = self
        detector.startMonitoring()
        let config = detector.currentConfigurationHash()

        if let snapshot = store.load(configHash: config) {
            windowCount = snapshot.windows.count
            lastSaveDate = snapshot.date
            statusItem?.menu = buildMenu()
        }

        print("[AppDelegate] Active config: \(config)")
    }

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

        let headerItem = NSMenuItem()
        let headerView = MenuHeaderView(windowCount: windowCount, lastSaveDate: lastSaveDate)
        let hostingView = NSHostingView(rootView: headerView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 240, height: 60)
        headerItem.view = hostingView
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        let saveItem = NSMenuItem(title: "Save Layout", action: #selector(saveLayout), keyEquivalent: "s")
        saveItem.target = self
        menu.addItem(saveItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit Lay", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    func monitorsDidChange() {
        print("[AppDelegate] Monitor change detected — waiting 1s...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.restoreAndVerify()
        }
    }

    @objc func saveLayout() {
        let config = detector.currentConfigurationHash()
        let windows = tracker.getAllWindows()
        store.save(windows: windows, configHash: config)
        windowCount = windows.count
        lastSaveDate = Date()
        statusItem?.menu = buildMenu()
        print("[AppDelegate] Saved \(windows.count) windows")
    }

    @objc func openSettings() {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView()
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Lay Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 480, height: 360))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
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

struct MenuHeaderView: View {
    let windowCount: Int
    let lastSaveDate: Date?

    var saveText: String {
        guard let date = lastSaveDate else { return "No layout saved yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Saved \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    var body: some View {
        HStack(spacing: 12) {
            // App icon
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 36, height: 36)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 3) {
                Text("Lay")
                    .font(.system(size: 13, weight: .semibold))
                HStack(spacing: 4) {
                    Text(saveText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    if windowCount > 0 {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(windowCount) windows")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
