import Foundation

struct TerminalTab: Identifiable, Hashable {
    let id: UUID
    var title: String
    var workingDirectory: URL

    init(
        id: UUID = UUID(),
        title: String = "Shell",
        workingDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.id = id
        self.title = title
        self.workingDirectory = workingDirectory
    }
}
