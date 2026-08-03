import AppKit
import SwiftUI

/// Owns the menu-bar item, the history popover, and the preferences/about windows.
@MainActor
final class StatusBarController {
    private let container: AppContainer
    private let statusItem: NSStatusItem
    private let popover = NSPopover()

    private var preferencesWindow: NSWindow?
    private var aboutWindow: NSWindow?

    init(container: AppContainer) {
        self.container = container
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureButton()
        configurePopover()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        button.image = NSImage(
            systemSymbolName: "list.clipboard",
            accessibilityDescription: "Clipo"
        )?.withSymbolConfiguration(config)
        button.image?.isTemplate = true
        button.action = #selector(handleClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        let viewModel = HistoryViewModel(
            repository: container.repository,
            clipboardService: container.clipboardService
        )
        let root = HistoryView(
            viewModel: viewModel,
            onOpenPreferences: { [weak self] in self?.openPreferences() },
            onOpenAbout: { [weak self] in self?.openAbout() },
            onQuit: { NSApp.terminate(nil) }
        )
        popover.contentViewController = NSHostingController(rootView: root)
        popover.behavior = .transient
        popover.animates = true
    }

    // MARK: - Interaction

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return togglePopover() }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showContextMenu() {
        let menu = StatusBarMenu.build(
            onShowHistory: { [weak self] in self?.togglePopover() },
            onPreferences: { [weak self] in self?.openPreferences() },
            onAbout: { [weak self] in self?.openAbout() }
        )
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Windows

    private func openPreferences() {
        popover.performClose(nil)
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = PreferencesView(
            viewModel: PreferencesViewModel(settingsService: container.settingsService)
        )
        let window = Self.makeWindow(title: "Preferences", content: view)
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openAbout() {
        popover.performClose(nil)
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = Self.makeWindow(title: "About Clipo", content: AboutView())
        aboutWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func makeWindow(title: String, content: some View) -> NSWindow {
        let hosting = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hosting)
        window.title = title
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
