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
    var sourceIcon: Data?
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
        sourceIcon: Data? = nil,
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
        self.sourceIcon = sourceIcon
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
        case sourceIcon = "source_icon"
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
    }
}
