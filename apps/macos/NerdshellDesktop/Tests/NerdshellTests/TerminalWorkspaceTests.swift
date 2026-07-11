import Foundation
import XCTest
@testable import Nerdshell

@MainActor
final class TerminalWorkspaceTests: XCTestCase {
    func testWorkspaceAlwaysHasAtLeastOneTab() {
        let workspace = TerminalWorkspace()
        workspace.closeSelectedTab()

        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertNotNil(workspace.selectedTab)
    }

    func testNewTabBecomesSelected() {
        let workspace = TerminalWorkspace()
        let originalID = workspace.selectedTabID

        workspace.addTab(workingDirectory: URL(fileURLWithPath: "/tmp"))

        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertNotEqual(workspace.selectedTabID, originalID)
        XCTAssertEqual(workspace.selectedTab?.workingDirectory.path, "/tmp")
    }
}
