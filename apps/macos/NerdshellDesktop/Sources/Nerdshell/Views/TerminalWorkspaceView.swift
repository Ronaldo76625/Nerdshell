import SwiftUI

struct TerminalWorkspaceView: View {
    @StateObject private var workspace = TerminalWorkspace()

    var body: some View {
        VStack(spacing: 0) {
            TerminalTabBar(
                tabs: workspace.tabs,
                selection: $workspace.selectedTabID,
                onAdd: { workspace.addTab() },
                onClose: workspace.closeSelectedTab
            )

            Divider()

            if let session = workspace.selectedSession {
                TerminalHostView(session: session)
                    .id(session.id)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .focusedValue(\.newTerminalTab, { workspace.addTab() })
        .focusedValue(\.closeTerminalTab, workspace.closeSelectedTab)
        .onDisappear {
            workspace.terminateAllSessions()
        }
    }
}
