# Package.swift

## Configuration

- **swift-tools-version:** 6.0
- **Package name:** swift-networking

## Platforms

```swift
platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .watchOS(.v9),
    .tvOS(.v16),
    .visionOS(.v1),
]
```

## Products

```swift
products: [
    .library(name: "Networking", targets: ["Networking"]),
    .library(name: "NetworkingWebSocket", targets: ["NetworkingWebSocket"]),
]
```

Two products. Most users only import `Networking`.

## Dependencies

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
]
```

SwiftSyntax is compile-time only (used by the macro target). Zero runtime external dependencies.

## Targets

```swift
// Core + SSE + macro declarations
.target(name: "Networking", dependencies: ["NetworkingMacros"])

// Macro implementations
.macro(name: "NetworkingMacros", dependencies: [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
])

// WebSocket
.target(name: "NetworkingWebSocket", dependencies: ["Networking"])
```

## Test Targets

```swift
.testTarget(name: "NetworkingTests", dependencies: ["Networking"])

.testTarget(name: "NetworkingMacroTests", dependencies: [
    "NetworkingMacros",
    .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
])

.testTarget(name: "NetworkingWebSocketTests", dependencies: ["NetworkingWebSocket"])
```

## Dependency Graph

```
Consumer app
├── import Networking           → Networking target
│   └── depends on               NetworkingMacros (compile-time only)
│       └── depends on            SwiftSyntax
└── import NetworkingWebSocket  → NetworkingWebSocket target (optional)
    └── depends on               Networking
```

SwiftSyntax does NOT ship in the consumer's binary.

## Summary

- 2 products
- 3 source targets
- 3 test targets
- 1 external dependency (compile-time only)
- 0 runtime external dependencies
