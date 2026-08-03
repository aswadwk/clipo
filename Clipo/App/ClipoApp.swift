import SwiftUI

@main
struct ClipoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The UI lives in the status bar popover (see StatusBarController).
        // This empty Settings scene keeps SwiftUI happy without showing a window.
        Settings {
            EmptyView()
        }
    }
}
