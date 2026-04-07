# Plan: Minimal End-to-End

Master issue: #5
Milestone: Minimal End-to-End

## Goal

A developer can define a `@Client` struct with `@GET`/`@POST` endpoints, create a `NetworkClient`, and make type-safe HTTP requests with JSON encoding/decoding.

## Implementation Layers

AC1 is split into 4 architectural layers, each with its own ATDD test. Layers 2 and 3 can be worked in parallel after Layer 1.

```
Layer 1 (#32) ─────┬──── Layer 2 (#33) ──── #9-12, #19-25 (11 issues)
                   │
                   ├──── Layer 3 (#34) ──── #26-30 (5 issues)
                   │
                   └──── Layer 4 (#6) ───── #7-8, #13-18 (8 issues)
                         (needs L2+L3)
```

### Layer 1 — Core Types (#32)
Request, Response, HTTPMethod, HeaderKey, RequestMetadata, RequestMetadataKey, NetworkError, ResponseDecoding, RequestEncoding.
ATDD: construct `Request.get("/users/123")` with all properties.

### Layer 2 — NetworkClient + Transport (#33)
Transport protocol, MockTransport, Request→URLRequest conversion, Response conversion, middleware chain (MiddlewareBuilder), NetworkClient.send()/data()/string().
ATDD: `NetworkClient.send(request, as: User.self)` decodes via MockTransport.
Blocked by: Layer 1.

### Layer 3 — Macros (#34)
MarkerMacro, @GET/@POST/@DELETE declarations, PathValidation, ClosureTypeParsing, ClientMacro, NetworkingMacrosPlugin.
ATDD: `assertMacroExpansion` generates correct `init(network:)`.
Blocked by: Layer 1. Parallel with Layer 2.

### Layer 4 — Integration (#6)
Full pipeline test: @Client with @GET("/{id}"), call endpoint, get decoded User.
ATDD: the original AC1 acceptance test.
Blocked by: Layers 2 + 3.

## Blocking Structure

| Blocked by Layer 2 | Blocked by Layer 3 | Blocked by Layer 4 |
|---|---|---|
| #9 AC4 (error status) | #26 AC21 (macro gen) | #7 AC2 (GET no params) |
| #10 AC5 (transport fail) | #27 AC22 (default path) | #8 AC3 (multi path params) |
| #11 AC6 (malformed body) | #28 AC23 (path mismatch) | #13 AC8 (POST happy path) |
| #12 AC7 (empty body) | #29 AC24 (multi methods) | #14 AC9 (encoding fail) |
| #19 AC14 (no middleware) | #30 AC25 (non-struct) | #15 AC10 (path + body) |
| #20 AC15 (single middleware) | | #16 AC11 (query + body) |
| #21 AC16 (middleware order) | | #17 AC12 (query params) |
| #22 AC17 (short-circuit) | | #18 AC13 (optional query) |
| #23 AC18 (Void return) | | |
| #24 AC19 (Data return) | | |
| #25 AC20 (String return) | | |

## Review Decisions

### Cherry-picks (added to scope)
- **CustomStringConvertible** on Request, Response, NetworkError — debugging ergonomics (Layer 1)
- **Custom `~=` operator** for `NetworkError.Kind` range matching — `case .invalidStatus(400...499)` (Layer 1)
- **Hybrid URL validation** — strip trailing slash, require scheme, prepend missing `/` (Layer 2)

### Architectural Decisions
1. **Encoding error wrapping:** Macro-generated code catches `EncodingError` and wraps in `NetworkError(.encodingFailed)` via do/catch
2. **URL construction failure:** precondition (programming error, validated at init)
3. **UTF-8 decode failure:** `NetworkError(.decodingFailed)` for consistency
4. **Special return type errors:** Void/Data/String still throw `.invalidStatus` on non-2xx

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
