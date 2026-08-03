import Foundation
import GRDB

/// Owns the SQLite connection and schema migrations.
final class DatabaseService {
    let dbQueue: DatabaseQueue

    init() throws {
        let fm = FileManager.default
        let appSupport = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = appSupport.appendingPathComponent("Clipo", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let dbURL = dir.appendingPathComponent("clipo.sqlite")

        var config = Configuration()
        config.foreignKeysEnabled = true
        dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)

        try Self.migrator.migrate(dbQueue)
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createClipboardItem") { db in
            try db.create(table: ClipboardItem.databaseTableName) { t in
                t.primaryKey("id", .text)
                t.column("content", .text).notNull()
                t.column("preview", .text).notNull()
                t.column("type", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("source_app_name", .text)
                t.column("source_bundle_identifier", .text)
                t.column("source_icon", .blob)
                t.column("usage_count", .integer).notNull().defaults(to: 0)
                t.column("is_favorite", .boolean).notNull().defaults(to: false)
                t.column("is_pinned", .boolean).notNull().defaults(to: false)
                t.column("size", .integer).notNull().defaults(to: 0)
            }

            try db.create(
                index: "idx_clipboard_item_created_at",
                on: ClipboardItem.databaseTableName,
                columns: ["created_at"]
            )
        }

        return migrator
    }
}
