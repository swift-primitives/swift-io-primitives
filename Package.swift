// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-io-primitives",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "IO Primitives",
            targets: ["IO Primitives"]
        ),
        .library(
            name: "IO Primitives Test Support",
            targets: ["IO Primitives Test Support"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IO Primitives",
            dependencies: []
        ),
        .target(
            name: "IO Primitives Test Support",
            dependencies: [
                "IO Primitives"
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "IO Primitives Tests",
            dependencies: [
                "IO Primitives",
                "IO Primitives Test Support",
            ],
            path: "Tests/IO Primitives Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
