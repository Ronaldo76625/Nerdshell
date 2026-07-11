import SwiftUI

struct TerminalHostView: NSViewRepresentable {
    @ObservedObject var session: TerminalSessionController

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        let terminal = session.terminalView
        terminal.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(terminal)

        NSLayoutConstraint.activate([
            terminal.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            terminal.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            terminal.topAnchor.constraint(equalTo: container.topAnchor),
            terminal.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        DispatchQueue.main.async {
            session.startIfNeeded()
            container.window?.makeFirstResponder(terminal)
        }
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
