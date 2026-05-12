import SwiftUI

// OnboardingView - Phase 8
// Shown on first launch if Accessibility permission is not granted

struct OnboardingView: View {

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            Text("Welcome to Lay")
                .font(.title)
                .fontWeight(.bold)

            Text("Lay automatically restores your window layout when you connect or disconnect a monitor.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Label("One permission required", systemImage: "lock.shield")
                    .fontWeight(.semibold)

                Text("Lay needs Accessibility access to read and restore window positions. Your data never leaves your Mac.")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }

            Button(action: openAccessibilitySettings) {
                Text("Open System Settings")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("After granting access, Lay starts working immediately.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(width: 380, height: 400)
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
