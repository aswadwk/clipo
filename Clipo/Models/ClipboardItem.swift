import Foundation
import GRDB

/// A single captured clipboard entry, persisted in SQLite via GRDB.
struct ClipboardItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: String
    var content: String
    var preview: String
    var type: ClipboardType
    var createdAt: Date
    var updatedAt: Date
    var sourceAppName: String?
    var sourceBundleIdentifier: String?
    /// DB-relative path to the cached source-app icon on disk (see `FileStorage`), never a blob.
    var sourceIconPath: String?
    /// DB-relative path to the image file on disk for `.image` items (see `FileStorage`).
    var imagePath: String?
    var usageCount: Int
    var isFavorite: Bool
    var isPinned: Bool
    var size: Int

    init(
        id: String = UUID().uuidString,
        content: String,
        preview: String,
        type: ClipboardType,
        createdAt: Date,
        updatedAt: Date,
        sourceAppName: String? = nil,
        sourceBundleIdentifier: String? = nil,
        sourceIconPath: String? = nil,
        imagePath: String? = nil,
        usageCount: Int = 0,
        isFavorite: Bool = false,
        isPinned: Bool = false,
        size: Int = 0
    ) {
        self.id = id
        self.content = content
        self.preview = preview
        self.type = type
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceAppName = sourceAppName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.sourceIconPath = sourceIconPath
        self.imagePath = imagePath
        self.usageCount = usageCount
        self.isFavorite = isFavorite
        self.isPinned = isPinned
        self.size = size
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case preview
        case type
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sourceAppName = "source_app_name"
        case sourceBundleIdentifier = "source_bundle_identifier"
        case sourceIconPath = "source_icon_path"
        case imagePath = "image_path"
        case usageCount = "usage_count"
        case isFavorite = "is_favorite"
        case isPinned = "is_pinned"
        case size
    }
}

// MARK: - GRDB

extension ClipboardItem: FetchableRecord, PersistableRecord {
    static let databaseTableName = "clipboard_item"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let content = Column(CodingKeys.content)
        static let preview = Column(CodingKeys.preview)
        static let type = Column(CodingKeys.type)
        static let createdAt = Column(CodingKeys.createdAt)
        static let isFavorite = Column(CodingKeys.isFavorite)
        static let isPinned = Column(CodingKeys.isPinned)
        static let imagePath = Column(CodingKeys.imagePath)
    }
}
