import Cocoa
import ApplicationServices

// WindowTracker - Phase 1
// Single responsibility: list all visible windows with their metadata
// Uses Accessibility API (AXUIElement) to read window info from running apps

struct WindowInfo {
    let app: String
    let title: String
    let frame: CGRect
}

class WindowTracker {

    // Request Accessibility permission and list all windows
    func requestAccessAndTrack() {
        let trusted = AXIsProcessTrusted()

        if !trusted {
            // Prompt the user to grant Accessibility access
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
            AXIsProcessTrustedWithOptions(options)
            print("[WindowTracker] Accessibility not granted yet — permission dialog shown")
            return
        }

        let windows = getAllWindows()
        print("[WindowTracker] Found \(windows.count) windows:")
        for w in windows {
            print("  App: \(w.app) | Title: \(w.title) | Frame: \(w.frame)")
        }
    }

    // Walk every running app and collect visible windows
    private func getAllWindows() -> [WindowInfo] {
        var result: [WindowInfo] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            guard let bundleID = app.bundleIdentifier else { continue }

            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let axWindows = windowsRef as? [AXUIElement] else { continue }

            for axWindow in axWindows {
                let title = getStringAttribute(axWindow, kAXTitleAttribute)
                let frame = getWindowFrame(axWindow)
                result.append(WindowInfo(app: bundleID, title: title, frame: frame))
            }
        }

        return result
    }

    private func getStringAttribute(_ element: AXUIElement, _ attribute: String) -> String {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &ref) == .success,
              let value = ref as? String else { return "" }
        return value
    }

    private func getWindowFrame(_ element: AXUIElement) -> CGRect {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return .zero
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)

        return CGRect(origin: position, size: size)
    }
}
