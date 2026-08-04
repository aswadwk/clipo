import Foundation
import CryptoKit

/// Off-database storage for large binaries: clipboard images and per-app source icons.
///
/// Keeps `clipo.sqlite` small by writing image bytes and cached icons to files under
/// the shared Application Support directory, so the database only ever holds their
/// relative paths. Paths are stored relative to `baseURL` so the DB stays portable.
final class FileStorage: Sendable {
    /// Root Clipo directory in Application Support, shared with the database file.
    let baseURL: URL
    private let imagesURL: URL
    private let iconsURL: URL

    init(baseDirectory: URL) throws {
        baseURL = baseDirectory
        imagesURL = baseDirectory.appendingPathComponent("images", isDirectory: true)
        iconsURL = baseDirectory.appendingPathComponent("icons", isDirectory: true)

        let fm = FileManager.default
        try fm.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: iconsURL, withIntermediateDirectories: true)
    }

    // MARK: - Images

    /// Persist clipboard image bytes to `images/<id>.tiff`, returning the DB-relative path.
    /// One file per item id keeps deletion a simple 1:1 cleanup.
    func storeImage(_ data: Data, id: String) throws -> String {
        let relativePath = "images/\(id).tiff"
        try data.write(to: baseURL.appendingPathComponent(relativePath), options: .atomic)
        return relativePath
    }

    /// Read stored image bytes back for a DB-relative path.
    func imageData(forRelativePath relativePath: String) -> Data? {
        try? Data(contentsOf: baseURL.appendingPathComponent(relativePath))
    }

    /// Delete a stored image file; a missing file is not an error.
    func deleteImage(relativePath: String) {
        try? FileManager.default.removeItem(at: baseURL.appendingPathComponent(relativePath))
    }

    // MARK: - Source icons (cached once per app bundle identifier)

    /// Cache a source-app icon keyed by bundle identifier so repeated captures from the
    /// same app reuse one file instead of duplicating a blob per row. Returns the
    /// DB-relative path, or `nil` when there is no stable key to cache under.
    func cacheIcon(_ data: Data, bundleIdentifier: String?) throws -> String? {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return nil }

        let relativePath = "icons/\(Self.sanitizedKey(bundleIdentifier)).tiff"
        let fileURL = baseURL.appendingPathComponent(relativePath)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try data.write(to: fileURL, options: .atomic)
        }
        return relativePath
    }

    // MARK: - Helpers

    /// Hex-encoded SHA-256 of the given bytes, used as a stable dedup key for images.
    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// Reduce a bundle identifier to a filesystem-safe, stable filename component.
    static func sanitizedKey(_ identifier: String) -> String {
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-_"
        )
        return String(identifier.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }
}
