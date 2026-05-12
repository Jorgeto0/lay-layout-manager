import Foundation

// LayoutStore - Phase 6
// Saves one layout snapshot per monitor configuration
// File name is based on the display configuration hash

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
    let configHash: String
    let windows: [WindowSnapshot]
}

class LayoutStore {

    private var storageDirectory: URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let dir = appSupport.appendingPathComponent("LayLayoutManager")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for configHash: String) -> URL? {
        // Sanitize hash for use as filename
        let safeName = configHash.replacingOccurrences(of: "|", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return storageDirectory?.appendingPathComponent("layout_\(safeName).json")
    }

    func save(windows: [WindowInfo], configHash: String) {
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

        let layout = LayoutSnapshot(date: Date(), configHash: configHash, windows: snapshots)

        guard let url = fileURL(for: configHash) else {
            print("[LayoutStore] ERROR: could not resolve storage path")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(layout)
            try data.write(to: url, options: .atomic)
            print("[LayoutStore] Saved \(snapshots.count) windows for config: \(configHash)")
        } catch {
            print("[LayoutStore] ERROR saving snapshot: \(error)")
        }
    }

    func load(configHash: String) -> LayoutSnapshot? {
        guard let url = fileURL(for: configHash) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(LayoutSnapshot.self, from: data)
            print("[LayoutStore] Loaded \(snapshot.windows.count) windows for config: \(configHash)")
            return snapshot
        } catch {
            print("[LayoutStore] No snapshot found for config: \(configHash)")
            return nil
        }
    }

    func listSavedConfigs() -> [String] {
        guard let dir = storageDirectory else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return files.filter { $0.hasPrefix("layout_") && $0.hasSuffix(".json") }
    }
}
