import SwiftUI
import Defaults
import KeyboardShortcuts

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @State private var section: Section = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            ScrollView {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 560, height: 400)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Section.allCases) { item in
                SidebarRow(section: item, isSelected: section == item) {
                    withAnimation(.easeOut(duration: 0.12)) { section = item }
                }
            }
            Spacer()
        }
        .padding(10)
        .frame(width: 168)
        .background(.quaternary.opacity(0.25))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch section {
        case .general: GeneralSettings(viewModel: viewModel)
        case .clipboard: ClipboardSettings()
        case .shortcut: ShortcutSettings()
        case .appearance: AppearanceSettings(viewModel: viewModel)
        }
    }
}

// MARK: - Sections

extension PreferencesView {
    enum Section: String, CaseIterable, Identifiable {
        case general, clipboard, shortcut, appearance

        var id: String { rawValue }

        var title: String {
            switch self {
            case .general: return "General"
            case .clipboard: return "Clipboard"
            case .shortcut: return "Shortcut"
            case .appearance: return "Appearance"
            }
        }

        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .clipboard: return "doc.on.clipboard.fill"
            case .shortcut: return "command"
            case .appearance: return "paintbrush.fill"
            }
        }

        var tint: Color {
            switch self {
            case .general: return .gray
            case .clipboard: return .blue
            case .shortcut: return .purple
            case .appearance: return .pink
            }
        }
    }
}

private struct SidebarRow: View {
    let section: PreferencesView.Section
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(section.tint.gradient)
                    )
                Text(section.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.selection.opacity(0.6)) : AnyShapeStyle(.clear))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable card

/// A titled group of settings rendered as a soft rounded card.
private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            VStack(spacing: 0) { content }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.quaternary.opacity(0.35))
                )
        }
    }
}

/// One labelled row inside a `SettingsCard`, with an optional description.
private struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            trailing
        }
        .padding(.vertical, 10)
    }
}

private struct RowDivider: View {
    var body: some View {
        Divider().opacity(0.4)
    }
}

// MARK: - Panels

private struct GeneralSettings: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @Default(.launchAtLogin) private var launchAtLogin
    @Default(.startHidden) private var startHidden

    var body: some View {
        SettingsCard(title: "Startup") {
            SettingsRow(title: "Launch at Login", subtitle: "Open Clipo automatically after you sign in.") {
                Toggle("", isOn: $launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, value in viewModel.setLaunchAtLogin(value) }
            }
            RowDivider()
            SettingsRow(title: "Start Hidden", subtitle: "Keep the window closed until you open it.") {
                Toggle("", isOn: $startHidden).labelsHidden().toggleStyle(.switch)
            }
        }
    }
}

private struct ClipboardSettings: View {
    @Default(.ignoreDuplicate) private var ignoreDuplicate
    @Default(.maximumHistory) private var maximumHistory
    @Default(.autoCleanupEnabled) private var autoCleanupEnabled
    @Default(.autoCleanupDays) private var autoCleanupDays

    var body: some View {
        VStack(spacing: 18) {
            SettingsCard(title: "Capture") {
                SettingsRow(title: "Ignore Duplicates", subtitle: "Skip items identical to the previous one.") {
                    Toggle("", isOn: $ignoreDuplicate).labelsHidden().toggleStyle(.switch)
                }
                RowDivider()
                SettingsRow(title: "Maximum History", subtitle: "How many items Clipo keeps.") {
                    Stepper("\(maximumHistory)", value: $maximumHistory, in: 50...100_000, step: 50)
                        .labelsHidden()
                    Text("\(maximumHistory)").font(.system(size: 13, weight: .medium)).monospacedDigit()
                }
            }

            SettingsCard(title: "Maintenance") {
                SettingsRow(title: "Auto Cleanup", subtitle: "Remove old items on a schedule.") {
                    Toggle("", isOn: $autoCleanupEnabled).labelsHidden().toggleStyle(.switch)
                }
                if autoCleanupEnabled {
                    RowDivider()
                    SettingsRow(title: "Remove After") {
                        Stepper("\(autoCleanupDays)", value: $autoCleanupDays, in: 1...365).labelsHidden()
                        Text("\(autoCleanupDays) days").font(.system(size: 13, weight: .medium)).monospacedDigit()
                    }
                }
            }
        }
    }
}

private struct ShortcutSettings: View {
    var body: some View {
        SettingsCard(title: "Global Shortcut") {
            SettingsRow(title: "Show History", subtitle: "Toggle the Clipo window from anywhere.") {
                KeyboardShortcuts.Recorder(for: .togglePopup)
            }
        }
    }
}

private struct AppearanceSettings: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @Default(.theme) private var theme
    @Default(.compactMode) private var compactMode

    var body: some View {
        SettingsCard(title: "Appearance") {
            SettingsRow(title: "Theme") {
                Picker("", selection: $theme) {
                    ForEach(AppTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
                .onChange(of: theme) { _, value in viewModel.applyTheme(value) }
            }
            RowDivider()
            SettingsRow(title: "Compact Mode", subtitle: "Show more items with tighter rows.") {
                Toggle("", isOn: $compactMode).labelsHidden().toggleStyle(.switch)
            }
        }
    }
}
