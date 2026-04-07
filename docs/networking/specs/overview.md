# Overview

## Project

A modern Swift networking library with macro-powered API definitions, structured concurrency, and a composable middleware system.

- **Repository:** swift-networking
- **Module name:** Networking
- **Personal use + open source**

## Platform Targets

- Apple-only for v1: iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+
- Transport protocol enables future Linux/SwiftNIO support without redesign

## Swift Version

- Swift 6 strict concurrency from day one
- All types are `Sendable`

## Module Structure

```
Sources/
├── Networking/           # Core + SSE + macro declarations
├── NetworkingMacros/     # .macro target (SwiftSyntax)
└── NetworkingWebSocket/  # WebSocket
Tests/
├── NetworkingTests/
├── NetworkingMacroTests/
└── NetworkingWebSocketTests/
```

- **Networking:** Core types (Request, Response, NetworkClient, Middleware, Transport, errors), SSE support, and macro declarations. Zero runtime external dependencies.
- **NetworkingMacros:** Macro implementations using SwiftSyntax. Compile-time only — not shipped in consumer binaries.
- **NetworkingWebSocket:** WebSocket support. Separate module because it's a different protocol with its own connection lifecycle.

SSE lives in core because it's HTTP streaming with text parsing — thin enough to include, and `NetworkClient.stream()` needs to be accessible from macro-generated code without extra imports.

## Future Modules (separate repositories)

- `swift-graphql` — GraphQL support, depends on Networking
- `swift-grpc` — gRPC support, depends on Networking

## Library Usable Without Macros

Core types (NetworkClient, Request, Response, Middleware, RequestMetadata) work standalone. Users can write `init(network:)` by hand. Macros are sugar, not a requirement.
