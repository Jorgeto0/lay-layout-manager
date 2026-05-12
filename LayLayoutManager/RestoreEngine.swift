import Cocoa
import ApplicationServices

// RestoreEngine - updated with smarter window matching
// Matches by title first, falls back to window index

class RestoreEngine {

    func restore(from snapshot: LayoutSnapshot) {
        print("[RestoreEngine] Starting restore of \(snapshot.windows.count) windows")
        for saved in snapshot.windows {
            restoreWindow(saved)
        }
        print("[RestoreEngine] Restore complete")
    }

    private func restoreWindow(_ saved: WindowSnapshot) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == saved.app && $0.activationPolicy == .regular
        }) else {
            print("[RestoreEngine] SKIP: app not running — \(saved.app)")
            return
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else { return }

        // Try title match first
        for axWindow in axWindows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
            let title = titleRef as? String ?? ""
            if title == saved.title {
                move(axWindow, to: CGPoint(x: saved.x, y: saved.y))
                resize(axWindow, to: CGSize(width: saved.width, height: saved.height))
                print("[RestoreEngine] Restored by title: \(saved.app) | \"\(saved.title)\"")
                return
            }
        }

        // Fallback: use window index
        if saved.index < axWindows.count {
            let axWindow = axWindows[saved.index]
            move(axWindow, to: CGPoint(x: saved.x, y: saved.y))
            resize(axWindow, to: CGSize(width: saved.width, height: saved.height))
            print("[RestoreEngine] Restored by index: \(saved.app) | index \(saved.index)")
            return
        }

        print("[RestoreEngine] SKIP: window not found — \(saved.app) | \"\(saved.title)\"")
    }

    private func move(_ window: AXUIElement, to point: CGPoint) {
        var position = point
        guard let value = AXValueCreate(.cgPoint, &position) else { return }
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }

    private func resize(_ window: AXUIElement, to size: CGSize) {
        var s = size
        guard let value = AXValueCreate(.cgSize, &s) else { return }
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }
}
