import Foundation

/// Composition root: builds and holds the app's long-lived services.
@MainActor
final class AppContainer {
    let database: DatabaseService
    let repository: ClipboardRepository
    let monitor: ClipboardMonitor
    let clipboardService: ClipboardService
    let settingsService: SettingsService
    let hotkeyService: HotkeyService

    init() {
        do {
            database = try DatabaseService()
        } catch {
            fatalError("Clipo: could not open database: \(error)")
        }
        repository = ClipboardRepository(database: database)
        monitor = ClipboardMonitor()
        clipboardService = ClipboardService(monitor: monitor, repository: repository)
        settingsService = SettingsService()
        hotkeyService = HotkeyService()
    }
}
