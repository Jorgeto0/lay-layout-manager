import Cocoa
import ApplicationServices

// WindowTracker - Phase 1 updated
// Smarter window identity: app + title + index fallback

struct WindowInfo {
    let app: String
    let title: String
    let index: Int
    let frame: CGRect
}

class WindowTracker {

    func requestAccessAndTrack() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
            AXIsProcessTrustedWithOptions(options)
            print("[WindowTracker] Accessibility not granted yet")
            return
        }
        let windows = getAllWindows()
        print("[WindowTracker] Found \(windows.count) windows")
    }

    func getAllWindows() -> [WindowInfo] {
        var result: [WindowInfo] = []

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            guard let bundleID = app.bundleIdentifier else { continue }

            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var windowsRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
                  let axWindows = windowsRef as? [AXUIElement] else { continue }

            for (index, axWindow) in axWindows.enumerated() {
                let title = getStringAttribute(axWindow, kAXTitleAttribute)
                let frame = getWindowFrame(axWindow)
                result.append(WindowInfo(app: bundleID, title: title, index: index, frame: frame))
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
