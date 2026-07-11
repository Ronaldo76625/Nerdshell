import Foundation

struct NerdshellEnvironment {
    let applicationSupportDirectory: URL

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.applicationSupportDirectory = base.appendingPathComponent("Nerdshell", isDirectory: true)
    }

    var profileDirectory: URL {
        applicationSupportDirectory
            .appendingPathComponent("profiles", isDirectory: true)
            .appendingPathComponent("default", isDirectory: true)
    }

    var shellEnvironment: [String: String] {
        var values = ProcessInfo.processInfo.environment
        values["NERDSHELL_PROFILE"] = profileDirectory.path
        values["NERDSHELL"] = "1"
        values["TERM"] = "xterm-256color"
        values["COLORTERM"] = "truecolor"
        values["ZDOTDIR"] = profileDirectory.appendingPathComponent("zdotdir").path
        values["STARSHIP_CONFIG"] = profileDirectory.appendingPathComponent("starship.toml").path
        values["EZA_CONFIG_DIR"] = profileDirectory.appendingPathComponent("eza").path
        return values
    }
}
