// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Paper",
    platforms: [.macOS(.v12)],
    targets: [
        .target(
            name: "PaperCore",
            path: "Sources/PaperCore"
        ),
        .executableTarget(
            name: "Paper",
            dependencies: ["PaperCore"],
            path: "Sources/Paper"
        ),
        .executableTarget(
            name: "docxprobe",
            dependencies: ["PaperCore"],
            path: "Tools/docxprobe"
        ),
    ]
)
