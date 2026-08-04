import AppKit
import Defaults

/// Wires the monitor to the repository: dedupes, persists captures, and copies items back out.
@MainActor
final class ClipboardService {
    private let monitor: ClipboardMonitor
    private let repository: ClipboardRepository
    private let fileStorage: FileStorage

    init(monitor: ClipboardMonitor, repository: ClipboardRepository, fileStorage: FileStorage) {
        self.monitor = monitor
        self.repository = repository
        self.fileStorage = fileStorage
    }

    func start() {
        monitor.onCapture = { [weak self] capture in
            self?.handle(capture)
        }
        monitor.start()
    }

    func stop() {
        monitor.stop()
    }

    private func handle(_ capture: ClipboardCapture) {
        do {
            if Defaults[.ignoreDuplicate],
               let recent = try repository.mostRecent(),
               recent.content == capture.content,
               recent.type == capture.type {
                return
            }

            let now = Date()
            let id = UUID().uuidString

            let imagePath = try capture.imageData.map { try fileStorage.storeImage($0, id: id) }
            let sourceIconPath = try capture.sourceIcon.flatMap {
                try fileStorage.cacheIcon($0, bundleIdentifier: capture.sourceBundleIdentifier)
            }

            let item = ClipboardItem(
                id: id,
                content: capture.content,
                preview: capture.preview,
                type: capture.type,
                createdAt: now,
                updatedAt: now,
                sourceAppName: capture.sourceAppName,
                sourceBundleIdentifier: capture.sourceBundleIdentifier,
                sourceIconPath: sourceIconPath,
                imagePath: imagePath,
                size: capture.size
            )
            try repository.insert(item)

            if Defaults[.autoCleanupEnabled] {
                try repository.enforceLimits(
                    maxItems: Defaults[.maximumHistory],
                    maxAgeDays: Defaults[.autoCleanupDays]
                )
            } else {
                try repository.enforceLimits(maxItems: Defaults[.maximumHistory], maxAgeDays: nil)
            }
        } catch {
            NSLog("Clipo: failed to persist capture: \(error)")
        }
    }

    /// Copy a stored item back to the system pasteboard.
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        monitor.suppressNextChange()
        pasteboard.clearContents()

        switch item.type {
        case .image:
            if let path = item.imagePath,
               let data = fileStorage.imageData(forRelativePath: path),
               let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            }
        case .file:
            let urls = item.content
                .split(separator: "\n")
                .map { URL(fileURLWithPath: String($0)) }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls as [NSURL])
            }
        default:
            pasteboard.setString(item.content, forType: .string)
        }

        try? repository.registerUse(id: item.id)
    }
}
