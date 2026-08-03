import SwiftUI
import Defaults
import KeyboardShortcuts

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    @Default(.launchAtLogin) private var launchAtLogin
    @Default(.startHidden) private var startHidden
    @Default(.ignoreDuplicate) private var ignoreDuplicate
    @Default(.maximumHistory) private var maximumHistory
    @Default(.autoCleanupEnabled) private var autoCleanupEnabled
    @Default(.autoCleanupDays) private var autoCleanupDays
    @Default(.theme) private var theme
    @Default(.compactMode) private var compactMode

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            clipboard.tabItem { Label("Clipboard", systemImage: "doc.on.clipboard") }
            shortcut.tabItem { Label("Shortcut", systemImage: "command") }
            appearance.tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 420, height: 260)
        .padding()
    }

    private var general: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, value in
                    viewModel.setLaunchAtLogin(value)
                }
            Toggle("Start Hidden", isOn: $startHidden)
        }
        .formStyle(.grouped)
    }

    private var clipboard: some View {
        Form {
            Toggle("Ignore Consecutive Duplicates", isOn: $ignoreDuplicate)
            Stepper("Maximum History: \(maximumHistory)", value: $maximumHistory, in: 50...100_000, step: 50)
            Toggle("Auto Cleanup", isOn: $autoCleanupEnabled)
            if autoCleanupEnabled {
                Stepper("Remove After: \(autoCleanupDays) days", value: $autoCleanupDays, in: 1...365)
            }
        }
        .formStyle(.grouped)
    }

    private var shortcut: some View {
        Form {
            KeyboardShortcuts.Recorder("Show Clipboard History", name: .togglePopup)
        }
        .formStyle(.grouped)
    }

    private var appearance: some View {
        Form {
            Picker("Theme", selection: $theme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .onChange(of: theme) { _, value in
                viewModel.applyTheme(value)
            }
            Toggle("Compact Mode", isOn: $compactMode)
        }
        .formStyle(.grouped)
    }
}
