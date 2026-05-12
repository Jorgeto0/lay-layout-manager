import Cocoa
import ApplicationServices

// RestoreEngine - Phase 3
// Single responsibility: move windows back to their saved positions
// Matches saved snapshots to current windows by app bundle ID + title

class RestoreEngine {

    func restore(from snapshot: LayoutSnapshot) {
        print("[RestoreEngine] Starting restore of \(snapshot.windows.count) windows")

        for saved in snapshot.windows {
            restoreWindow(saved)
        }

        print("[RestoreEngine] Restore complete")
    }

    private func restoreWindow(_ saved: WindowSnapshot) {
        // Find the running app that matches the saved bundle ID
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == saved.app && $0.activationPolicy == .regular
        }) else {
            print("[RestoreEngine] SKIP: app not running — \(saved.app)")
            return
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else {
            print("[RestoreEngine] SKIP: could not get windows for \(saved.app)")
            return
        }

        // Match window by title
        for axWindow in axWindows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
            let title = titleRef as? String ?? ""

            if title == saved.title {
                move(axWindow, to: CGPoint(x: saved.x, y: saved.y))
                resize(axWindow, to: CGSize(width: saved.width, height: saved.height))
                print("[RestoreEngine] Restored: \(saved.app) | \"\(saved.title)\"")
                return
            }
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
