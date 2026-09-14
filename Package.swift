// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "kdna-app-shared",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "KDNAAppShared", targets: ["KDNAAppShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aikdna/kdna-core-swift.git", revision: "0b85375b7e92b9ca4591f92c1e814018a4fb95b8"),
    ],
    targets: [
        .target(
            name: "KDNAAppShared",
            dependencies: [.product(name: "KDNACore", package: "kdna-core-swift")],
            path: "Sources/KDNAAppShared",
            exclude: ["AuthorizationPresentation.swift"]
        ),
        .testTarget(
            name: "KDNAAppSharedTests",
            dependencies: ["KDNAAppShared"],
            exclude: ["AuthorizationPresentationTests.swift"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
