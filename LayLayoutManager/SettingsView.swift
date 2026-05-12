import SwiftUI

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab { case general, layouts, pro }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape", selected: selectedTab == .general) { selectedTab = .general }
                TabButton(title: "Layouts", icon: "rectangle.3.group", selected: selectedTab == .layouts) { selectedTab = .layouts }
                TabButton(title: "Pro", icon: "star", selected: selectedTab == .pro) { selectedTab = .pro }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            Group {
                switch selectedTab {
                case .general: GeneralTab()
                case .layouts: LayoutsTab()
                case .pro: ProTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480, height: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(width: 80, height: 52)
            .background(selected ? Color.accentColor.opacity(0.12) : Color.clear)
            .foregroundColor(selected ? .accentColor : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab
struct GeneralTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @AppStorage("autoSave") private var autoSave = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch at Login")
                        .font(.system(size: 13, weight: .medium))
                    Text("Lay starts automatically when you log in")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, value in
                        let manager = LoginItemManager()
                        value ? manager.enable() : manager.disable()
                    }
            }

            Divider().padding(.horizontal, 20)

            SettingsRow {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Auto-save Layout")
                            .font(.system(size: 13, weight: .medium))
                        ProBadge()
                    }
                    Text("Automatically saves when windows move")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: .constant(false))
                    .toggleStyle(.switch)
                    .disabled(true)
            }

            Divider().padding(.horizontal, 20)

            SettingsRow {
                Text("Version")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Layouts Tab
struct LayoutsTab: View {
    @State private var configs: [SavedLayoutInfo] = []
    let store = LayoutStore()

    struct SavedLayoutInfo: Identifiable {
        let id = UUID()
        let filename: String
        let displayName: String
        let windowCount: Int
        let date: Date?
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if configs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No layouts saved yet")
                        .font(.system(size: 13, weight: .medium))
                    Text("Click Save Layout from the menu bar to get started")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(configs) { info in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: info.displayName.contains("2") ? "display.2" : "display")
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(info.displayName)
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(info.windowCount) windows saved")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let date = info.date {
                                    Text(date, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .onAppear { loadConfigs() }
    }

    private func loadConfigs() {
        let filenames = store.listSavedConfigs()
        configs = filenames.compactMap { filename in
            let hash = filename
                .replacingOccurrences(of: "layout_", with: "")
                .replacingOccurrences(of: ".json", with: "")
                .replacingOccurrences(of: "_", with: "|")

            guard let snapshot = store.load(configHash: hash) else { return nil }

            let screenParts = hash.components(separatedBy: "|")
            let screenCount = screenParts.filter { $0.contains("x") }.count
            let name = screenCount <= 1 ? "MacBook only" : "\(screenCount) displays connected"

            return SavedLayoutInfo(
                filename: filename,
                displayName: name,
                windowCount: snapshot.windows.count,
                date: snapshot.date
            )
        }
    }
}

// MARK: - Pro Tab
struct ProTab: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.yellow)
                Text("Lay Pro")
                    .font(.system(size: 20, weight: .bold))
                Text("Everything, unlocked")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ProFeatureRow(icon: "rectangle.3.group", text: "Unlimited monitor profiles")
                ProFeatureRow(icon: "arrow.clockwise", text: "Auto-save when windows move")
                ProFeatureRow(icon: "sparkles", text: "All future features, free")
            }

            VStack(spacing: 8) {
                Button(action: {}) {
                    Text("Try Free for 7 Days")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("$1.99 per month or $14.99 per year after trial")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.yellow.opacity(0.2))
            .foregroundColor(.orange)
            .cornerRadius(4)
    }
}

struct SettingsRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack { content() }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }
}
