import SwiftUI

// SettingsView - Clean settings window with tabs
// General, Layouts, Pro

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab {
        case general, layouts, pro
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape", selected: selectedTab == .general) {
                    selectedTab = .general
                }
                TabButton(title: "Layouts", icon: "rectangle.3.group", selected: selectedTab == .layouts) {
                    selectedTab = .layouts
                }
                TabButton(title: "Pro", icon: "star", selected: selectedTab == .pro) {
                    selectedTab = .pro
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralTab()
                case .layouts:
                    LayoutsTab()
                case .pro:
                    ProTab()
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
                    Text("Automatically save when windows move")
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version")
                        .font(.system(size: 13, weight: .medium))
                }
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
    let store = LayoutStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let configs = store.listSavedConfigs()

            if configs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No layouts saved yet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("Click Save Layout from the menu bar to get started")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(configs, id: \.self) { config in
                            LayoutRow(config: config)
                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }
}

struct LayoutRow: View {
    let config: String

    var displayName: String {
        if config.contains("_") {
            let parts = config
                .replacingOccurrences(of: "layout_", with: "")
                .replacingOccurrences(of: ".json", with: "")
                .components(separatedBy: "_")
            let screenCount = parts.filter { $0.contains("x") }.count
            return screenCount == 1 ? "MacBook only" : "\(screenCount) displays"
        }
        return config
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "display")
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 13, weight: .medium))
                Text(config
                    .replacingOccurrences(of: "layout_", with: "")
                    .replacingOccurrences(of: ".json", with: ""))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Pro Tab
struct ProTab: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                Text("Lay Pro")
                    .font(.system(size: 20, weight: .bold))
                Text("Unlock everything")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                ProFeatureRow(icon: "rectangle.3.group", text: "Unlimited monitor profiles")
                ProFeatureRow(icon: "arrow.clockwise", text: "Auto-save when windows move")
                ProFeatureRow(icon: "sparkles", text: "All future features")
            }

            VStack(spacing: 8) {
                Button(action: {}) {
                    Text("Start Free Trial — 7 Days")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Then $1.99/month or $14.99/year")
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
        HStack {
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
