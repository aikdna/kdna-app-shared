// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "kdna-app-shared",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "KDNAAppShared", targets: ["KDNAAppShared"]),
    ],
    dependencies: [
        // Pin Core until the next stable tag includes the current LoadPlan/runtime APIs.
        .package(url: "https://github.com/aikdna/kdna-core-swift.git", revision: "0c94032bea8677167e7d57e8d914d9e29bef9edf"),
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
