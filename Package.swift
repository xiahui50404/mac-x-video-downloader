// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XVideoDownloader",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "XVideoDownloader")
    ]
)
