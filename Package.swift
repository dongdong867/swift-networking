// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-networking",
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
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
