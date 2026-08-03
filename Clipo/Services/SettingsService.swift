import AppKit
import ServiceManagement
import Defaults

/// Thin wrapper over Defaults plus OS-level side effects (launch at login).
@MainActor
final class SettingsService {
    func setLaunchAtLogin(_ enabled: Bool) {
        Defaults[.launchAtLogin] = enabled
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Clipo: launch-at-login change failed: \(error)")
        }
    }

    func applyTheme(_ theme: AppTheme) {
        switch theme {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
