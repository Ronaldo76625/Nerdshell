import AppKit
import Combine
@preconcurrency import SwiftTerm

@MainActor
final class TerminalSessionController: NSObject, ObservableObject, Identifiable {
    let id: UUID
    let tab: TerminalTab
    let terminalView: LocalProcessTerminalView

    @Published private(set) var state: TerminalEngineState = .idle
    @Published private(set) var title: String
    @Published private(set) var currentDirectory: String

    private var hasStarted = false

    init(tab: TerminalTab) {
        self.id = tab.id
        self.tab = tab
        self.title = tab.title
        self.currentDirectory = tab.workingDirectory.path
        self.terminalView = LocalProcessTerminalView(frame: .zero)
        super.init()
        terminalView.processDelegate = self
        configureAppearance()
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        do {
            try ProfileManager().prepareProfile()
            let environment = NerdshellEnvironment().shellEnvironment
                .map { "\($0.key)=\($0.value)" }
                .sorted()
            let shell = preferredShell()
            let loginName = "-" + URL(fileURLWithPath: shell).lastPathComponent

            terminalView.startProcess(
                executable: shell,
                environment: environment,
                execName: loginName,
                currentDirectory: tab.workingDirectory.path
            )
            state = .running(processIdentifier: 0)
        } catch {
            state = .failed(message: error.localizedDescription)
            terminalView.feed(text: "\r\nNerdshell could not start: \(error.localizedDescription)\r\n")
        }
    }

    func terminate() {
        guard hasStarted else { return }
        terminalView.terminate()
        hasStarted = false
    }

    private func preferredShell() -> String {
        let configured = UserDefaults.standard.string(forKey: "terminalShellPath")
        let candidates = [configured, ProcessInfo.processInfo.environment["SHELL"], "/bin/zsh"]
        return candidates.compactMap { $0 }.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "/bin/zsh"
    }

    private func configureAppearance() {
        let preferredName = UserDefaults.standard.string(forKey: "terminalFontName") ?? "JetBrainsMono Nerd Font Mono"
        let size = UserDefaults.standard.double(forKey: "terminalFontSize")
        let pointSize = size > 0 ? size : 14
        terminalView.font = NSFont(name: preferredName, size: pointSize)
            ?? NSFont.monospacedSystemFont(ofSize: pointSize, weight: .regular)

        let background = NSColor(calibratedRed: 0.039, green: 0.055, blue: 0.086, alpha: 1)
        let foreground = NSColor(calibratedRed: 0.753, green: 0.792, blue: 0.961, alpha: 1)
        terminalView.nativeBackgroundColor = background
        terminalView.nativeForegroundColor = foreground
        terminalView.caretColor = NSColor(calibratedRed: 0.620, green: 0.886, blue: 0.545, alpha: 1)
        terminalView.layer?.backgroundColor = background.cgColor
        terminalView.optionAsMetaKey = true
    }

}

extension TerminalSessionController: @preconcurrency LocalProcessTerminalViewDelegate {
    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        self.title = title
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let directory,
              let url = URL(string: directory) else { return }
        currentDirectory = url.path
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        state = .exited(status: exitCode ?? -1)
    }
}
