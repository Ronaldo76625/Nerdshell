import Foundation

enum ProfileManagerError: LocalizedError {
    case bundledProfileMissing

    var errorDescription: String? {
        switch self {
        case .bundledProfileMissing:
            return "The bundled Nerdshell profile could not be found."
        }
    }
}

struct ProfileManager {
    private let fileManager: FileManager
    private let environment: NerdshellEnvironment

    init(fileManager: FileManager = .default, environment: NerdshellEnvironment = .init()) {
        self.fileManager = fileManager
        self.environment = environment
    }

    func prepareProfile() throws {
        let profile = environment.profileDirectory
        let zdotdir = profile.appendingPathComponent("zdotdir", isDirectory: true)
        try fileManager.createDirectory(at: zdotdir, withIntermediateDirectories: true)

        guard let resources = Bundle.main.resourceURL else {
            throw ProfileManagerError.bundledProfileMissing
        }

        let configs = resources.appendingPathComponent("configs", isDirectory: true)
        guard fileManager.fileExists(atPath: configs.path) else {
            throw ProfileManagerError.bundledProfileMissing
        }

        try install(
            configs.appendingPathComponent("zsh/zshrc"),
            at: zdotdir.appendingPathComponent(".zshrc"),
            suffix: """

            # Nerdshell Desktop isolation overrides
            export HISTFILE="$NERDSHELL_PROFILE/history"
            export EZA_CONFIG_DIR="$NERDSHELL_PROFILE/eza"
            """
        )
        try install(configs.appendingPathComponent("zsh/zprofile"), at: zdotdir.appendingPathComponent(".zprofile"))
        try install(configs.appendingPathComponent("zsh/zshenv"), at: zdotdir.appendingPathComponent(".zshenv"))
        try install(configs.appendingPathComponent("starship/starship.toml"), at: profile.appendingPathComponent("starship.toml"))

        let ezaDirectory = profile.appendingPathComponent("eza", isDirectory: true)
        try fileManager.createDirectory(at: ezaDirectory, withIntermediateDirectories: true)
        try install(configs.appendingPathComponent("eza/theme.yml"), at: ezaDirectory.appendingPathComponent("theme.yml"))
    }

    private func install(_ source: URL, at destination: URL, suffix: String = "") throws {
        guard fileManager.fileExists(atPath: source.path) else {
            throw ProfileManagerError.bundledProfileMissing
        }

        var data = try Data(contentsOf: source)
        if !suffix.isEmpty, let suffixData = suffix.data(using: .utf8) {
            data.append(suffixData)
        }
        if (try? Data(contentsOf: destination)) == data { return }
        try data.write(to: destination, options: .atomic)
    }
}
