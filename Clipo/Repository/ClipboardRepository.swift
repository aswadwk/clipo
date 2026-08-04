import Foundation
import GRDB

/// Database access layer for clipboard items. ViewModels talk to this, never GRDB directly.
final class ClipboardRepository {
    private let dbQueue: DatabaseQueue
    private let fileStorage: FileStorage

    init(database: DatabaseService, fileStorage: FileStorage) {
        self.dbQueue = database.dbQueue
        self.fileStorage = fileStorage
    }

    // MARK: - Reads

    func all() throws -> [ClipboardItem] {
        try dbQueue.read { db in
            try ClipboardItem
                .order(ClipboardItem.Columns.isPinned.desc, ClipboardItem.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    /// Observe the full ordered list; the callback fires on every change.
    func observeAll(onChange: @escaping ([ClipboardItem]) -> Void) -> DatabaseCancellable {
        let observation = ValueObservation.tracking { db in
            try ClipboardItem
                .order(ClipboardItem.Columns.isPinned.desc, ClipboardItem.Columns.createdAt.desc)
                .fetchAll(db)
        }
        return observation.start(
            in: dbQueue,
            scheduling: .async(onQueue: .main),
            onError: { _ in },
            onChange: onChange
        )
    }

    func mostRecent() throws -> ClipboardItem? {
        try dbQueue.read { db in
            try ClipboardItem
                .order(ClipboardItem.Columns.createdAt.desc)
                .fetchOne(db)
        }
    }

    // MARK: - Writes

    func insert(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try item.insert(db)
        }
    }

    func update(_ item: ClipboardItem) throws {
        try dbQueue.write { db in
            try item.update(db)
        }
    }

    func toggleFavorite(id: String) throws {
        try dbQueue.write { db in
            guard var item = try ClipboardItem.fetchOne(db, key: id) else { return }
            item.isFavorite.toggle()
            item.updatedAt = Date()
            try item.update(db)
        }
    }

    func togglePinned(id: String) throws {
        try dbQueue.write { db in
            guard var item = try ClipboardItem.fetchOne(db, key: id) else { return }
            item.isPinned.toggle()
            item.updatedAt = Date()
            try item.update(db)
        }
    }

    func registerUse(id: String) throws {
        try dbQueue.write { db in
            guard var item = try ClipboardItem.fetchOne(db, key: id) else { return }
            item.usageCount += 1
            item.updatedAt = Date()
            try item.update(db)
        }
    }

    // MARK: - Deletes

    func delete(id: String) throws {
        let removed = try dbQueue.write { db -> [String] in
            let imagePath = try ClipboardItem.fetchOne(db, key: id)?.imagePath
            try ClipboardItem.deleteOne(db, key: id)
            return [imagePath].compactMap { $0 }
        }
        deleteImageFiles(removed)
    }

    func clearAll() throws {
        let removed = try dbQueue.write { db -> [String] in
            let paths = try imagePaths(db, of: ClipboardItem.all())
            try ClipboardItem.deleteAll(db)
            return paths
        }
        deleteImageFiles(removed)
    }

    func clearUnpinned() throws {
        let removed = try dbQueue.write { db -> [String] in
            let unpinned = ClipboardItem.filter(ClipboardItem.Columns.isPinned == false)
            let paths = try imagePaths(db, of: unpinned)
            try unpinned.deleteAll(db)
            return paths
        }
        deleteImageFiles(removed)
    }

    // MARK: - Cleanup

    /// Enforce the configured limits, never removing pinned items.
    func enforceLimits(maxItems: Int, maxAgeDays: Int?) throws {
        let removed = try dbQueue.write { db -> [String] in
            var removedPaths: [String] = []

            if let maxAgeDays, maxAgeDays > 0 {
                let cutoff = Date().addingTimeInterval(-Double(maxAgeDays) * 86_400)
                let expired = ClipboardItem
                    .filter(ClipboardItem.Columns.isPinned == false)
                    .filter(ClipboardItem.Columns.createdAt < cutoff)
                removedPaths += try imagePaths(db, of: expired)
                try expired.deleteAll(db)
            }

            let unpinnedCount = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .fetchCount(db)

            if unpinnedCount > maxItems {
                let overflow = unpinnedCount - maxItems
                let stale = ClipboardItem
                    .filter(ClipboardItem.Columns.isPinned == false)
                    .order(ClipboardItem.Columns.createdAt.asc)
                    .limit(overflow)
                let staleItems = try stale.fetchAll(db)
                removedPaths += staleItems.compactMap(\.imagePath)
                try ClipboardItem.deleteAll(db, keys: staleItems.map(\.id))
            }

            return removedPaths
        }
        deleteImageFiles(removed)
    }

    // MARK: - Image file cleanup

    /// Collect the on-disk image paths for the rows matched by `request`.
    private func imagePaths(_ db: Database, of request: QueryInterfaceRequest<ClipboardItem>) throws -> [String] {
        try String.fetchAll(
            db,
            request
                .select(ClipboardItem.Columns.imagePath)
                .filter(ClipboardItem.Columns.imagePath != nil)
        )
    }

    /// Remove offloaded image files for deleted rows so disk usage tracks the DB.
    private func deleteImageFiles(_ relativePaths: [String]) {
        for path in relativePaths {
            fileStorage.deleteImage(relativePath: path)
        }
    }
}
