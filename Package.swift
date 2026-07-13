// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "kdna-app-shared",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "KDNAAppShared", targets: ["KDNAAppShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aikdna/kdna-core-swift.git", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "KDNAAppShared",
            dependencies: [.product(name: "KDNACore", package: "kdna-core-swift")],
            path: "Sources/KDNAAppShared"
        ),
        .testTarget(
            name: "KDNAAppSharedTests",
            dependencies: ["KDNAAppShared"]
        ),
    ]
)
