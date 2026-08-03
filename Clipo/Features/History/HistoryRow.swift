import SwiftUI

/// One clipboard item in the history list, styled as a soft card.
struct HistoryRow: View {
    let item: ClipboardItem
    var compact: Bool
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 11) {
            icon

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .lineLimit(compact ? 1 : 2)
                    .font(compact ? .callout : .body)
                    .foregroundStyle(.primary)

                if !compact {
                    HStack(spacing: 5) {
                        if let app = item.sourceAppName {
                            Text(app)
                            Text("·")
                        }
                        Text(item.createdAt.relativeDescription)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            badges

            if isHovering {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.accentColor))
                }
                .buttonStyle(.plain)
                .help("Copy")
                .transition(.opacity)

                Menu {
                    Button("Copy", action: onCopy)
                    Button(item.isFavorite ? "Unfavorite" : "Favorite", action: onToggleFavorite)
                    Button(item.isPinned ? "Unpin" : "Pin", action: onTogglePin)
                    Divider()
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, compact ? 6 : 9)
        .contentShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .fill(isHovering ? AnyShapeStyle(.selection.opacity(0.5)) : AnyShapeStyle(.clear))
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .onTapGesture(perform: onCopy)
    }

    private var icon: some View {
        Image(systemName: item.type.symbolName)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(item.type.tint)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.type.tint.opacity(0.14))
            )
    }

    @ViewBuilder
    private var badges: some View {
        if item.isPinned {
            Image(systemName: "pin.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
        }
        if item.isFavorite {
            Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundStyle(.yellow)
        }
    }
}

/// Accent color per clipboard type — a UI concern kept out of the model.
private extension ClipboardType {
    var tint: Color {
        switch self {
        case .plainText: return .gray
        case .richText: return .indigo
        case .html: return .orange
        case .image: return .pink
        case .file: return .blue
        case .pdf: return .red
        case .url: return .teal
        }
    }
}
