import SwiftUI
import Defaults

/// Root content of the status-bar popover: header, search, filter, and the clipboard list.
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Default(.compactMode) private var compactMode

    var onOpenPreferences: () -> Void
    var onOpenAbout: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 8) {
                SearchView(text: $viewModel.searchText)
                filterBar
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.4)

            list

            Divider().opacity(0.4)

            footer
        }
        .frame(width: Constants.UI.popoverWidth, height: Constants.UI.popoverHeight)
        .onAppear { viewModel.start() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(Constants.appName)
                .font(.system(.headline, design: .rounded).weight(.semibold))

            if !viewModel.items.isEmpty {
                Text("\(viewModel.items.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }

            Spacer()

            Menu {
                Button("Clear Unpinned", action: viewModel.clearUnpinned)
                Button("Clear All History", role: .destructive, action: viewModel.clearAll)
                Divider()
                Button("Preferences…", action: onOpenPreferences)
                Button("About Clipo", action: onOpenAbout)
                Divider()
                Button("Quit Clipo", action: onQuit)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Filter pills

    private var filterBar: some View {
        HStack(spacing: 6) {
            ForEach(HistoryViewModel.Filter.allCases) { filter in
                FilterPill(
                    title: filter.title,
                    icon: filter.icon,
                    isSelected: viewModel.filter == filter
                ) {
                    withAnimation(.easeOut(duration: 0.15)) { viewModel.filter = filter }
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        let items = viewModel.filteredItems
        if items.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.tertiary)
                Text(viewModel.searchText.isEmpty ? "No clipboard history yet" : "No results")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if viewModel.searchText.isEmpty {
                    Text("Copy anything to get started.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: Constants.UI.rowSpacing) {
                    ForEach(items) { item in
                        HistoryRow(
                            item: item,
                            compact: compactMode,
                            onCopy: { viewModel.copy(item) },
                            onToggleFavorite: { viewModel.toggleFavorite(item) },
                            onTogglePin: { viewModel.togglePin(item) },
                            onDelete: { viewModel.delete(item) }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            FooterButton(icon: "gearshape", help: "Preferences", action: onOpenPreferences)

            Spacer()

            Text("⌘⇧V to toggle")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()

            FooterButton(icon: "info.circle", help: "About", action: onOpenAbout)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

/// A pill-shaped filter toggle.
private struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(
                    isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)
                )
            )
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
        }
        .buttonStyle(.plain)
    }
}

/// A borderless icon button used in the footer.
private struct FooterButton: View {
    let icon: String
    let help: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isHovering ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovering = $0 }
    }
}
