import Foundation
import GRDB

/// Database access layer for clipboard items. ViewModels talk to this, never GRDB directly.
final class ClipboardRepository {
    private let dbQueue: DatabaseQueue

    init(database: DatabaseService) {
        self.dbQueue = database.dbQueue
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
        _ = try dbQueue.write { db in
            try ClipboardItem.deleteOne(db, key: id)
        }
    }

    func clearAll() throws {
        _ = try dbQueue.write { db in
            try ClipboardItem.deleteAll(db)
        }
    }

    func clearUnpinned() throws {
        _ = try dbQueue.write { db in
            try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .deleteAll(db)
        }
    }

    // MARK: - Cleanup

    /// Enforce the configured limits, never removing pinned items.
    func enforceLimits(maxItems: Int, maxAgeDays: Int?) throws {
        try dbQueue.write { db in
            if let maxAgeDays, maxAgeDays > 0 {
                let cutoff = Date().addingTimeInterval(-Double(maxAgeDays) * 86_400)
                try ClipboardItem
                    .filter(ClipboardItem.Columns.isPinned == false)
                    .filter(ClipboardItem.Columns.createdAt < cutoff)
                    .deleteAll(db)
            }

            let unpinnedCount = try ClipboardItem
                .filter(ClipboardItem.Columns.isPinned == false)
                .fetchCount(db)

            if unpinnedCount > maxItems {
                let overflow = unpinnedCount - maxItems
                let staleIDs = try String.fetchAll(
                    db,
                    ClipboardItem
                        .select(ClipboardItem.Columns.id)
                        .filter(ClipboardItem.Columns.isPinned == false)
                        .order(ClipboardItem.Columns.createdAt.asc)
                        .limit(overflow)
                )
                try ClipboardItem.deleteAll(db, keys: staleIDs)
            }
        }
    }
}
