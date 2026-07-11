import AppKit
import SwiftUI

@main
struct NerdshellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Nerdshell", id: "terminal") {
            TerminalWorkspaceView()
                .frame(minWidth: 720, minHeight: 460)
        }
        .defaultSize(width: 1_000, height: 680)
        .commands {
            NerdshellCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
