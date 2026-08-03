import Foundation
import Defaults

extension Defaults.Keys {
    // General
    static let launchAtLogin = Key<Bool>("launchAtLogin", default: false)
    static let startHidden = Key<Bool>("startHidden", default: true)

    // Clipboard
    static let ignoreDuplicate = Key<Bool>("ignoreDuplicate", default: true)
    static let maximumHistory = Key<Int>("maximumHistory", default: 1000)
    static let autoCleanupEnabled = Key<Bool>("autoCleanupEnabled", default: true)
    static let autoCleanupDays = Key<Int>("autoCleanupDays", default: 30)

    // Appearance
    static let theme = Key<AppTheme>("theme", default: .system)
    static let compactMode = Key<Bool>("compactMode", default: false)
}

enum AppTheme: String, Codable, CaseIterable, Defaults.Serializable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
