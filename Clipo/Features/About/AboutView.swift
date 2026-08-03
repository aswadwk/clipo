import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            VStack(spacing: 3) {
                Text(Constants.appName)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("Version \(Constants.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("A lightweight, native clipboard manager for macOS.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Divider().frame(width: 180)

            Text("© 2026 Aswad")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(width: 320, height: 300)
        .padding()
    }
}
