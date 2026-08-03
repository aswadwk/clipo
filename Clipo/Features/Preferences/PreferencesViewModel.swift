import Foundation
import Defaults

@MainActor
final class PreferencesViewModel: ObservableObject {
    private let settingsService: SettingsService

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settingsService.setLaunchAtLogin(enabled)
    }

    func applyTheme(_ theme: AppTheme) {
        settingsService.applyTheme(theme)
    }
}
