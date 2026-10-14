// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Paper",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "Paper",
            path: "Sources/Paper"
        ),
    ]
)
