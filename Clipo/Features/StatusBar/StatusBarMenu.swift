import AppKit

/// Builds the right-click menu shown from the status-bar item.
enum StatusBarMenu {
    static func build(
        onShowHistory: @escaping () -> Void,
        onPreferences: @escaping () -> Void,
        onAbout: @escaping () -> Void
    ) -> NSMenu {
        let menu = NSMenu()

        menu.addItem(actionItem("Show Clipboard History", key: "v", handler: onShowHistory))
        menu.addItem(.separator())
        menu.addItem(actionItem("Preferences…", key: ",", handler: onPreferences))
        menu.addItem(actionItem("About Clipo", key: "", handler: onAbout))
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Clipo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    private static func actionItem(_ title: String, key: String, handler: @escaping () -> Void) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(MenuActionTarget.run(_:)), keyEquivalent: key)
        let target = MenuActionTarget(handler: handler)
        item.target = target
        item.representedObject = target // retain the target for the menu item's lifetime
        return item
    }
}

/// Bridges an NSMenuItem selector to a Swift closure.
private final class MenuActionTarget: NSObject {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func run(_ sender: NSMenuItem) {
        handler()
    }
}
