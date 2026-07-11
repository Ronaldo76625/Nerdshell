import Foundation
import Combine

@MainActor
final class TerminalWorkspace: ObservableObject {
    @Published private(set) var tabs: [TerminalTab]
    @Published var selectedTabID: TerminalTab.ID?
    private var sessions: [TerminalTab.ID: TerminalSessionController] = [:]

    init(tabs: [TerminalTab] = [TerminalTab()]) {
        self.tabs = tabs.isEmpty ? [TerminalTab()] : tabs
        self.selectedTabID = self.tabs.first?.id
        for tab in self.tabs {
            sessions[tab.id] = TerminalSessionController(tab: tab)
        }
    }

    var selectedTab: TerminalTab? {
        tabs.first { $0.id == selectedTabID }
    }

    var selectedSession: TerminalSessionController? {
        guard let selectedTabID else { return nil }
        return sessions[selectedTabID]
    }

    func addTab(workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        let tab = TerminalTab(workingDirectory: workingDirectory)
        tabs.append(tab)
        sessions[tab.id] = TerminalSessionController(tab: tab)
        selectedTabID = tab.id
    }

    func closeSelectedTab() {
        guard let selectedTabID,
              let index = tabs.firstIndex(where: { $0.id == selectedTabID }) else {
            return
        }

        tabs.remove(at: index)
        sessions.removeValue(forKey: selectedTabID)?.terminate()

        if tabs.isEmpty {
            addTab()
        } else {
            self.selectedTabID = tabs[min(index, tabs.count - 1)].id
        }
    }

    func terminateAllSessions() {
        sessions.values.forEach { $0.terminate() }
        sessions.removeAll()
    }
}
