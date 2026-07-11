import Foundation

/// Boundary between the macOS interface and the future PTY/emulation backend.
/// UI code must depend on this contract rather than on a concrete terminal library.
protocol TerminalEngine: AnyObject {
    var state: TerminalEngineState { get }

    func start(shell: URL, workingDirectory: URL, environment: [String: String]) throws
    func send(_ bytes: Data)
    func resize(columns: Int, rows: Int)
    func stop()
}

enum TerminalEngineState: Equatable {
    case idle
    case running(processIdentifier: Int32)
    case exited(status: Int32)
    case failed(message: String)
}
