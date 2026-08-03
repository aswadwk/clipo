import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global shortcut to toggle the clipboard popup. Default: ⌘⇧V.
    static let togglePopup = Self("togglePopup", default: .init(.v, modifiers: [.command, .shift]))
}

/// Registers the global shortcut and forwards it to a handler.
@MainActor
final class HotkeyService {
    func registerToggle(_ handler: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .togglePopup, action: handler)
    }
}
