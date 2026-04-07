# Plan: Minimal End-to-End

Master issue: #5
Milestone: Minimal End-to-End

## Goal

A developer can define a `@Client` struct with `@GET`/`@POST` endpoints, create a `NetworkClient`, and make type-safe HTTP requests with JSON encoding/decoding.

## Package.swift

Targets and dependencies are added when needed — not all at once upfront.

After this milestone, `Package.swift` contains:
- `Networking` target (core types + macro declarations)
- `NetworkingMacros` target (macro implementations, depends on SwiftSyntax)
- `NetworkingTests` target
- `NetworkingMacroTests` target (depends on `SwiftSyntaxMacrosTestSupport`)

`NetworkingWebSocket` target is NOT added in this milestone.

## File Structure After Milestone

```
Sources/Networking/
├── Client/
│   └── NetworkClient.swift
├── Request/
│   ├── Request.swift
│   ├── HTTPMethod.swift
│   ├── RequestMetadata.swift
│   └── RequestMetadataKey.swift
├── Response/
│   └── Response.swift
├── Middleware/
│   ├── Middleware.swift
│   └── MiddlewareBuilder.swift
├── Transport/
│   └── Transport.swift
├── Encoding/
│   ├── ResponseDecoding.swift
│   ├── RequestEncoding.swift
│   └── HeaderKey.swift
├── Errors/
│   └── NetworkError.swift
└── Macros/
    └── MacroDeclarations.swift

Sources/NetworkingMacros/
├── NetworkingMacrosPlugin.swift
├── MarkerMacro.swift
├── ClientMacro.swift
└── Utilities/
    ├── ClosureTypeParsing.swift
    └── PathValidation.swift

Tests/NetworkingTests/
├── RequestTests.swift
├── ResponseTests.swift
├── HTTPMethodTests.swift
├── RequestMetadataTests.swift
├── NetworkClientTests.swift
├── MiddlewareTests.swift
├── NetworkErrorTests.swift
├── URLRequestConversionTests.swift
└── Helpers/
    └── MockTransport.swift

Tests/NetworkingMacroTests/
├── ClientMacroTests.swift
├── MarkerMacroTests.swift
└── PathValidationTests.swift
```

## Testing Strategy

### Mock Transport

All `NetworkClient` tests use a `MockTransport` — no real HTTP calls.

```swift
struct MockTransport: Transport {
    var handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }

    func bytes(_ request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        fatalError("Not used in this milestone")
    }

    func upload(_ request: URLRequest, from data: Data) -> TransportTask {
        fatalError("Not used in this milestone")
    }

    func download(_ request: URLRequest) -> TransportTask {
        fatalError("Not used in this milestone")
    }
}
```

`MockTransport` is created early and reused by every subsequent AC.

### Test Types

For each AC:
- `Decodable` test types (`User`, `CreateUserRequest`, etc.) defined in test helpers
- Each test constructs a `NetworkClient` with `MockTransport`
- Assertions on the `URLRequest` that reaches the mock (method, URL, headers, body)
- Assertions on the decoded return value

### Macro Tests

Use `assertMacroExpansion` from `SwiftSyntaxMacrosTestSupport`. Tests verify:
- Generated code matches expected expansion
- Diagnostics (errors/warnings) are emitted for invalid input

## Architectural Notes

### Request → URLRequest Conversion

Happens inside `NetworkClient`, not `Transport`. The conversion:
1. Combine `baseURL` + `request.path` → `URL`
2. Set `request.query` → `URL.queryItems`
3. Set `request.headers` → `URLRequest.allHTTPHeaderFields`
4. Set `request.body` → `URLRequest.httpBody`
5. Set `request.method.rawValue` → `URLRequest.httpMethod`

`Transport` receives a fully-formed `URLRequest`.

### Middleware Chain Building

`NetworkClient` builds the chain using `reduce`:

```swift
let chain = middleware.reversed().reduce(transport) { next, mw in
    { request in try await mw.intercept(request: request, next: next) }
}
```

The outermost middleware is first in the array, innermost (closest to transport) is last.

### Body Encoding

The macro-generated code encodes the body, not `NetworkClient`:

```swift
// Macro generates:
.body(try network.defaultEncoder.encode(body))
```

`NetworkClient.send()` receives a `Request` with `body: Data?` already encoded. It just passes it through.

### Error Wrapping

The library only wraps errors from its own pipeline into `NetworkError`:
- Non-2xx status → `.invalidStatus(statusCode)`
- `DecodingError` from decoder → `.decodingFailed(underlying)`
- Error from transport → `.transportFailed(underlying)`
- `EncodingError` from encoder → `.encodingFailed(underlying)`

Middleware-thrown errors pass through untouched — they are NOT wrapped into `NetworkError`. This gives middleware authors and consumers full control over custom error types:

```swift
// Library errors:
catch let error as NetworkError { switch error.kind { ... } }

// Middleware errors pass through as-is:
catch let error as AuthError { ... }
```
