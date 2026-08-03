import Foundation

/// The kind of data a clipboard item holds.
enum ClipboardType: String, Codable, CaseIterable, Sendable {
    case plainText
    case richText
    case html
    case image
    case file
    case pdf
    case url

    var displayName: String {
        switch self {
        case .plainText: return "Plain Text"
        case .richText: return "Rich Text"
        case .html: return "HTML"
        case .image: return "Image"
        case .file: return "File"
        case .pdf: return "PDF"
        case .url: return "URL"
        }
    }

    /// SF Symbol name used in the UI.
    var symbolName: String {
        switch self {
        case .plainText: return "doc.plaintext"
        case .richText: return "doc.richtext"
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        case .file: return "folder"
        case .pdf: return "doc.text"
        case .url: return "link"
        }
    }
}
