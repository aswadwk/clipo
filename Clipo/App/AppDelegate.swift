import AppKit
import Defaults

/// App lifecycle owner. Builds the container, starts monitoring, and installs the status bar item.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var container: AppContainer!
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = AppContainer()
        self.container = container

        container.settingsService.applyTheme(Defaults[.theme])
        container.clipboardService.start()

        statusBar = StatusBarController(container: container)

        container.hotkeyService.registerToggle { [weak self] in
            self?.statusBar.togglePopover()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container?.clipboardService.stop()
    }
}
