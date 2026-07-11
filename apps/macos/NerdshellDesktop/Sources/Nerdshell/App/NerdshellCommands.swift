import SwiftUI

struct NewTerminalTabActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct CloseTerminalTabActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var newTerminalTab: (() -> Void)? {
        get { self[NewTerminalTabActionKey.self] }
        set { self[NewTerminalTabActionKey.self] = newValue }
    }

    var closeTerminalTab: (() -> Void)? {
        get { self[CloseTerminalTabActionKey.self] }
        set { self[CloseTerminalTabActionKey.self] = newValue }
    }
}

struct NerdshellCommands: Commands {
    @FocusedValue(\.newTerminalTab) private var newTerminalTab
    @FocusedValue(\.closeTerminalTab) private var closeTerminalTab

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") { newTerminalTab?() }
                .keyboardShortcut("t")
                .disabled(newTerminalTab == nil)
        }

        CommandGroup(before: .windowArrangement) {
            Button("Close Tab") { closeTerminalTab?() }
                .keyboardShortcut("w")
                .disabled(closeTerminalTab == nil)
        }
    }
}
