import Foundation
import Combine
import GRDB

@MainActor
final class HistoryViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case favorites
        case pinned

        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "History"
            case .favorites: return "Favorites"
            case .pinned: return "Pinned"
            }
        }
        var icon: String {
            switch self {
            case .all: return "clock"
            case .favorites: return "star"
            case .pinned: return "pin"
            }
        }
    }

    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchText: String = ""
    @Published var filter: Filter = .all

    private let repository: ClipboardRepository
    private let clipboardService: ClipboardService
    private var observation: DatabaseCancellable?

    init(repository: ClipboardRepository, clipboardService: ClipboardService) {
        self.repository = repository
        self.clipboardService = clipboardService
    }

    func start() {
        guard observation == nil else { return }
        observation = repository.observeAll { [weak self] items in
            self?.items = items
        }
    }

    var filteredItems: [ClipboardItem] {
        let scoped: [ClipboardItem]
        switch filter {
        case .all: scoped = items
        case .favorites: scoped = items.filter(\.isFavorite)
        case .pinned: scoped = items.filter(\.isPinned)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return scoped }
        return scoped.filter { item in
            item.preview.lowercased().contains(query)
                || item.content.lowercased().contains(query)
                || (item.sourceAppName?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Actions

    func copy(_ item: ClipboardItem) {
        clipboardService.copyToPasteboard(item)
    }

    func toggleFavorite(_ item: ClipboardItem) {
        try? repository.toggleFavorite(id: item.id)
    }

    func togglePin(_ item: ClipboardItem) {
        try? repository.togglePinned(id: item.id)
    }

    func delete(_ item: ClipboardItem) {
        try? repository.delete(id: item.id)
    }

    func clearAll() {
        try? repository.clearAll()
    }

    func clearUnpinned() {
        try? repository.clearUnpinned()
    }
}
