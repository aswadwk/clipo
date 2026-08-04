import AppKit

/// Raw snapshot of what was on the pasteboard at one moment, before persistence.
struct ClipboardCapture {
    /// For text/URL/file items this is the literal value; for images it is the SHA-256
    /// hex of the image bytes, used purely as a dedup key (`imageData` holds the pixels).
    var content: String
    var preview: String
    var type: ClipboardType
    var sourceAppName: String?
    var sourceBundleIdentifier: String?
    /// Raw 32×32 source-app icon bytes; the service caches these to disk per bundle id.
    var sourceIcon: Data?
    /// Raw image bytes for `.image` captures; the service offloads these to disk.
    var imageData: Data? = nil
    var size: Int
}

/// Polls `NSPasteboard.general` for changes and emits a `ClipboardCapture` for each new value.
@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    /// Fired on the main actor whenever the clipboard changes to a readable value.
    var onCapture: ((ClipboardCapture) -> Void)?

    /// Change count Clipo itself caused (e.g. copying an item back) — ignored to avoid loops.
    private var suppressChangeCount: Int?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func start(interval: TimeInterval = 0.5) {
        stop()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Mark the next observed change (caused by us writing to the pasteboard) as one to skip.
    func suppressNextChange() {
        suppressChangeCount = pasteboard.changeCount + 1
    }

    private func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        if let suppress = suppressChangeCount, suppress == current {
            suppressChangeCount = nil
            return
        }

        guard let capture = readPasteboard() else { return }
        onCapture?(capture)
    }

    private func readPasteboard() -> ClipboardCapture? {
        let source = sourceApp()

        if let url = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL,
           !url.isFileURL {
            let text = url.absoluteString
            return ClipboardCapture(
                content: text,
                preview: text,
                type: .url,
                sourceAppName: source.name,
                sourceBundleIdentifier: source.bundleID,
                sourceIcon: source.icon,
                size: text.utf8.count
            )
        }

        if let files = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           files.allSatisfy(\.isFileURL), !files.isEmpty {
            let joined = files.map(\.path).joined(separator: "\n")
            let names = files.map { $0.lastPathComponent }.joined(separator: ", ")
            return ClipboardCapture(
                content: joined,
                preview: names,
                type: .file,
                sourceAppName: source.name,
                sourceBundleIdentifier: source.bundleID,
                sourceIcon: source.icon,
                size: joined.utf8.count
            )
        }

        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let data = image.tiffRepresentation {
            return ClipboardCapture(
                content: FileStorage.sha256Hex(data),
                preview: "Image \(Int(image.size.width))×\(Int(image.size.height))",
                type: .image,
                sourceAppName: source.name,
                sourceBundleIdentifier: source.bundleID,
                sourceIcon: source.icon,
                imageData: data,
                size: data.count
            )
        }

        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let isRich = pasteboard.data(forType: .rtf) != nil
            let isHTML = pasteboard.data(forType: .html) != nil
            let type: ClipboardType = isHTML ? .html : (isRich ? .richText : .plainText)
            return ClipboardCapture(
                content: string,
                preview: String(string.prefix(200)),
                type: type,
                sourceAppName: source.name,
                sourceBundleIdentifier: source.bundleID,
                sourceIcon: source.icon,
                size: string.utf8.count
            )
        }

        return nil
    }

    private func sourceApp() -> (name: String?, bundleID: String?, icon: Data?) {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return (nil, nil, nil)
        }
        let icon = app.icon.flatMap { image -> Data? in
            let target = NSImage(size: NSSize(width: 32, height: 32))
            target.lockFocus()
            image.draw(in: NSRect(x: 0, y: 0, width: 32, height: 32))
            target.unlockFocus()
            return target.tiffRepresentation
        }
        return (app.localizedName, app.bundleIdentifier, icon)
    }
}
