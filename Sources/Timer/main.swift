import AppKit
import Combine
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
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermission()
        setupMainMenu()
        setupStatusItem()
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

    // MARK: - Menu bar status item (RunCat 스타일)

    /// 메뉴바에 남은 시간을 표시하는 상태 아이템을 만든다.
    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            // 숫자 폭이 매초 흔들리지 않도록 고정폭 숫자 폰트 사용.
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        self.statusItem = item

        // 남은 시간/모드/실행 상태가 바뀔 때마다 메뉴바 표시를 갱신한다.
        model.$remaining.combineLatest(model.$mode, model.$isRunning)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)
        updateStatusItem()
    }

    /// 모드별 이모지(🔥 집중 / 💤 휴식)와 MM:SS 남은 시간을 메뉴바에 표시한다.
    private func updateStatusItem() {
        let emoji = model.mode == .focus ? "🔥" : "💤"
        let m = model.remaining / 60
        let s = model.remaining % 60
        statusItem?.button?.title = String(format: "%@ %d:%02d", emoji, m, s)
    }

    /// 메뉴바 아이템을 클릭하면 타이머를 재생/정지 토글한다.
    @objc private func statusItemClicked() {
        model.toggle()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular) // show a Dock icon and app menu
let delegate = AppDelegate()
app.delegate = delegate
app.run()
