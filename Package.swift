// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-networking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [.package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")],
    targets: [
        .target(
            name: "Networking"
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]
        ),
    ]
)
