import Cocoa
import ApplicationServices

// ReconciliationEngine - Phase 5
// Single responsibility: verify windows are in correct position after restore
// Retries up to 3 times if a window didn't land correctly

class ReconciliationEngine {

    private let maxRetries = 3
    private let retryDelay = 0.3 // seconds
    private let tolerance: CGFloat = 10.0 // pixels of acceptable error

    func verify(snapshot: LayoutSnapshot, attempt: Int = 1) {
        print("[ReconciliationEngine] Verification attempt \(attempt)")

        var mismatches: [WindowSnapshot] = []

        for saved in snapshot.windows {
            if let mismatch = checkWindow(saved) {
                mismatches.append(mismatch)
            }
        }

        if mismatches.isEmpty {
            print("[ReconciliationEngine] All windows verified correctly ✓")
            return
        }

        print("[ReconciliationEngine] \(mismatches.count) mismatch(es) found")

        if attempt >= maxRetries {
            print("[ReconciliationEngine] Max retries reached — giving up on \(mismatches.count) window(s)")
            for w in mismatches {
                print("[ReconciliationEngine] FAILED: \(w.app) | \"\(w.title)\"")
            }
            return
        }

        // Retry mismatched windows after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            let restoreEngine = RestoreEngine()
            let retrySnapshot = LayoutSnapshot(date: snapshot.date, windows: mismatches)
            restoreEngine.restore(from: retrySnapshot)

            DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) {
                self.verify(snapshot: snapshot, attempt: attempt + 1)
            }
        }
    }

    // Returns the snapshot if the window is NOT in the correct position
    private func checkWindow(_ saved: WindowSnapshot) -> WindowSnapshot? {
        guard let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == saved.app && $0.activationPolicy == .regular
        }) else { return nil }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindows = windowsRef as? [AXUIElement] else { return nil }

        for axWindow in axWindows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
            let title = titleRef as? String ?? ""
            guard title == saved.title else { continue }

            // Read actual position
            var posRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &posRef) == .success else { return nil }
            var actualPosition = CGPoint.zero
            AXValueGetValue(posRef as! AXValue, .cgPoint, &actualPosition)

            let expectedPosition = CGPoint(x: saved.x, y: saved.y)
            let dx = abs(actualPosition.x - expectedPosition.x)
            let dy = abs(actualPosition.y - expectedPosition.y)

            if dx > tolerance || dy > tolerance {
                print("[ReconciliationEngine] MISMATCH: \(saved.app) | \"\(saved.title)\" expected (\(Int(saved.x)),\(Int(saved.y))) got (\(Int(actualPosition.x)),\(Int(actualPosition.y)))")
                return saved
            }

            return nil
        }

        return nil
    }
}
