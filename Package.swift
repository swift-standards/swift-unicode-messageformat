// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-unicode-messageformat",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "Unicode Message Format", targets: ["Unicode Message Format"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-bcp-47.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-8259.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-unicode-cldr.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Unicode Message Format",
            dependencies: [
                .product(name: "BCP 47", package: "swift-bcp-47"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Unicode CLDR", package: "swift-unicode-cldr"),
            ]
        ),
        .testTarget(
            name: "Unicode Message Format Tests",
            dependencies: [
                .target(name: "Unicode Message Format"),
                .product(name: "RFC 8259", package: "swift-rfc-8259"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
