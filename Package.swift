// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Charlie",
    platforms: [.iOS(.v17)],
    targets: [
        .target(name: "Charlie", path: "Charlie")
    ]
)
