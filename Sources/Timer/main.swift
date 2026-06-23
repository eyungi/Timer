import AppKit
import SwiftUI
import UserNotifications

/// Borderless floating panel that can still take keyboard/mouse focus
/// so the SwiftUI controls inside it stay interactive.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var panel: FloatingPanel!
    private let model = TimerModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()
        setupMainMenu()
        let root = ContentView(onClose: { [weak self] in self?.panel?.orderOut(nil) })
            .environmentObject(model)
        let hosting = NSHostingView(rootView: root)
        hosting.layoutSubtreeIfNeeded()
        let fit = hosting.fittingSize
        let size = NSSize(width: 184, height: fit.height > 1 ? fit.height : 204)
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hosting
        panel.setContentSize(size)

        // Position near the top-right corner of the primary screen
        // (the one with the menu bar) so it lands predictably.
        if let screen = NSScreen.screens.first {
            let v = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: v.maxX - size.width - 24, y: v.maxY - size.height - 24))
        } else {
            panel.center()
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    /// Re-show the panel when the user clicks the Dock icon after closing it.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        panel?.orderFrontRegardless()
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    /// 단계 완료 알림을 띄우기 위한 권한 요청. .app 번들에서만 동작한다.
    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// 앱이 맨 앞에 있을 때도 알림 배너가 뜨도록 한다.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "타이머 숨기기", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        NSApp.mainMenu = mainMenu
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular) // show a Dock icon and app menu
let delegate = AppDelegate()
app.delegate = delegate
app.run()
