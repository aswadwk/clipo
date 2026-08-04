import Foundation
import GRDB

/// Owns the SQLite connection and schema migrations.
final class DatabaseService {
    let dbQueue: DatabaseQueue
    /// Shared Clipo directory in Application Support, holding the DB and the binary files.
    let storageDirectory: URL

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
        storageDirectory = dir

        let dbURL = dir.appendingPathComponent("clipo.sqlite")

        var config = Configuration()
        config.foreignKeysEnabled = true
        dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)

        try Self.migrator(storageDirectory: dir).migrate(dbQueue)
    }

    private static func migrator(storageDirectory: URL) -> DatabaseMigrator {
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

        // Move image bytes and source icons out of the DB and into files on disk,
        // replacing the base64 image `content` and the `source_icon` blob with paths.
        migrator.registerMigration("offloadBinariesToFiles") { db in
            try db.alter(table: ClipboardItem.databaseTableName) { t in
                t.add(column: "image_path", .text)
                t.add(column: "source_icon_path", .text)
            }

            let fm = FileManager.default
            try fm.createDirectory(
                at: storageDirectory.appendingPathComponent("images", isDirectory: true),
                withIntermediateDirectories: true
            )
            try fm.createDirectory(
                at: storageDirectory.appendingPathComponent("icons", isDirectory: true),
                withIntermediateDirectories: true
            )

            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT id, type, content, source_icon, source_bundle_identifier
                FROM clipboard_item
                """
            )
            for row in rows {
                let id: String = row["id"]
                let type: String = row["type"]

                if type == ClipboardType.image.rawValue,
                   let base64: String = row["content"],
                   let data = Data(base64Encoded: base64) {
                    let relativePath = "images/\(id).tiff"
                    try data.write(
                        to: storageDirectory.appendingPathComponent(relativePath),
                        options: .atomic
                    )
                    try db.execute(
                        sql: "UPDATE clipboard_item SET image_path = ?, content = ? WHERE id = ?",
                        arguments: [relativePath, FileStorage.sha256Hex(data), id]
                    )
                }

                // Legacy icon blobs are only migratable when keyed by a bundle identifier,
                // matching how new captures cache icons; iconless-key rows just drop the icon.
                if let iconData: Data = row["source_icon"],
                   let bundleID: String = row["source_bundle_identifier"], !bundleID.isEmpty {
                    let relativePath = "icons/\(FileStorage.sanitizedKey(bundleID)).tiff"
                    let fileURL = storageDirectory.appendingPathComponent(relativePath)
                    if !fm.fileExists(atPath: fileURL.path) {
                        try iconData.write(to: fileURL, options: .atomic)
                    }
                    try db.execute(
                        sql: "UPDATE clipboard_item SET source_icon_path = ? WHERE id = ?",
                        arguments: [relativePath, id]
                    )
                }
            }

            try db.alter(table: ClipboardItem.databaseTableName) { t in
                t.drop(column: "source_icon")
            }
        }

        return migrator
    }
}
