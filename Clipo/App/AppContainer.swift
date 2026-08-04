import Foundation

/// Composition root: builds and holds the app's long-lived services.
@MainActor
final class AppContainer {
    let database: DatabaseService
    let fileStorage: FileStorage
    let repository: ClipboardRepository
    let monitor: ClipboardMonitor
    let clipboardService: ClipboardService
    let settingsService: SettingsService
    let hotkeyService: HotkeyService

    init() {
        do {
            database = try DatabaseService()
            fileStorage = try FileStorage(baseDirectory: database.storageDirectory)
        } catch {
            fatalError("Clipo: could not open storage: \(error)")
        }
        repository = ClipboardRepository(database: database, fileStorage: fileStorage)
        monitor = ClipboardMonitor()
        clipboardService = ClipboardService(monitor: monitor, repository: repository, fileStorage: fileStorage)
        settingsService = SettingsService()
        hotkeyService = HotkeyService()
    }
}
