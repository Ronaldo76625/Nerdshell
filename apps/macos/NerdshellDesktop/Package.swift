// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NerdshellDesktop",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Nerdshell", targets: ["Nerdshell"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/migueldeicaza/SwiftTerm.git",
            exact: "1.14.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Nerdshell",
            dependencies: ["SwiftTerm"],
            path: "Sources/Nerdshell",
            resources: [.process("Resources")]
        )
    ]
)
