import Foundation

// LayoutStore - Phase 2
// Single responsibility: save and load window layout snapshots as JSON
// Snapshots are stored in Application Support folder

struct WindowSnapshot: Codable {
    let app: String
    let title: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct LayoutSnapshot: Codable {
    let date: Date
    let windows: [WindowSnapshot]
}

class LayoutStore {

    private let fileName = "layout_snapshot.json"

    private var storageURL: URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let dir = appSupport.appendingPathComponent("LayLayoutManager")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir.appendingPathComponent(fileName)
    }

    func save(windows: [WindowInfo]) {
        let snapshots = windows.map { w in
            WindowSnapshot(
                app: w.app,
                title: w.title,
                x: w.frame.origin.x,
                y: w.frame.origin.y,
                width: w.frame.size.width,
                height: w.frame.size.height
            )
        }

        let layout = LayoutSnapshot(date: Date(), windows: snapshots)

        guard let url = storageURL else {
            print("[LayoutStore] ERROR: could not resolve storage path")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(layout)
            try data.write(to: url, options: .atomic)
            print("[LayoutStore] Saved \(snapshots.count) windows to \(url.path)")
        } catch {
            print("[LayoutStore] ERROR saving snapshot: \(error)")
        }
    }

    func load() -> LayoutSnapshot? {
        guard let url = storageURL else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(LayoutSnapshot.self, from: data)
            print("[LayoutStore] Loaded \(snapshot.windows.count) windows from snapshot dated \(snapshot.date)")
            return snapshot
        } catch {
            print("[LayoutStore] No snapshot found or error loading: \(error)")
            return nil
        }
    }
}
