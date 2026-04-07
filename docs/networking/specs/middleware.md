# Middleware

## Protocol

```swift
protocol Middleware: Sendable {
    func intercept(
        request: Request,
        next: @Sendable (Request) async throws -> Response
    ) async throws -> Response
}
```

Onion pattern: everything before `next()` runs on the request path, everything after runs on the response path (reverse order).

```swift
struct AuthMiddleware: Middleware {
    var tokenProvider: @Sendable () async throws -> String

    func intercept(
        request: Request,
        next: @Sendable (Request) async throws -> Response
    ) async throws -> Response {
        guard request.metadata.requiresAuth else {
            return try await next(request)
        }
        let token = try await tokenProvider()
        return try await next(
            request.header(.authorization, "Bearer \(token)")
        )
    }
}
```

## Execution Order

```swift
NetworkClient(baseURL: "...") {
    Logger()         // 1st to see request, last to see response
    Authenticate {}  // 2nd
    Retry()          // 3rd — wraps in retry
    Cache()          // 4th — closest to transport
}
```

```
Request  → Logger → Authenticate → Retry → Cache → Transport
Response ← Logger ← Authenticate ← Retry ← Cache ←
```

## MiddlewareGroup

Compose middleware into reusable groups (SwiftUI-style):

```swift
protocol MiddlewareGroup: Middleware {
    @MiddlewareBuilder
    var body: [any Middleware] { get }
}
```

Default `intercept` implementation chains through all middleware in `body`.

```swift
struct AuthenticatedMiddleware: MiddlewareGroup {
    var tokenStore: TokenStore

    var body: [any Middleware] {
        Logger()
        Authenticate { try await tokenStore.current }
        Retry(.exponential(max: 3))
    }
}
```

Groups nest freely:

```swift
NetworkClient(baseURL: "...") {
    AuthenticatedMiddleware(tokenStore: tokenStore)
    Cache(storage: .memory(limit: .megabytes(50)))
}
```

## MiddlewareBuilder

Result builder supporting conditionals and loops:

```swift
@resultBuilder
struct MiddlewareBuilder {
    static func buildBlock(_ components: any Middleware...) -> [any Middleware]
    static func buildOptional(_ component: [any Middleware]?) -> [any Middleware]
    static func buildEither(first component: [any Middleware]) -> [any Middleware]
    static func buildEither(second component: [any Middleware]) -> [any Middleware]
    static func buildArray(_ components: [[any Middleware]]) -> [any Middleware]
}
```

```swift
NetworkClient(baseURL: "...") {
    Logger()
    if useAuth {
        Authenticate { ... }
    }
    Retry()
}
```

## Inline Helpers

### Intercept — full control

```swift
Intercept { request, next in
    let start = ContinuousClock.now
    let response = try await next(request)
    print("Duration: \(start.elapsed)")
    return response
}
```

### MapRequest — modify request before sending

```swift
MapRequest { request in
    request
        .header(.custom("X-App-Version"), Bundle.main.appVersion)
        .header(.custom("X-Platform"), "iOS")
}
```

### MapResponse — modify response after receiving

```swift
MapResponse { response in
    var response = response
    // envelope unwrapping
    if let inner = try? JSONSerialization.jsonObject(with: response.body) as? [String: Any],
       let data = inner["data"] {
        response.body = try JSONSerialization.data(withJSONObject: data)
    }
    return response
}
```

### OnContext — act on a specific metadata key

```swift
OnContext(\.rateLimit) { limit, request in
    await rateLimiter.acquire(limit: limit)
    return request
}
```

Only executes when the key has a value. For optional metadata keys from `@Context`.

## Built-in Middleware

| Middleware | Configuration | Reads from metadata |
|---|---|---|
| `Logger(level:, logBody:, redactHeaders:)` | Verbose mode available | — |
| `Authenticate(provider:, refreshOn:, refresh:)` | Bearer token, refresh flow | `requiresAuth` |
| `Retry(defaultPolicy:)` | Exponential/fixed/immediate | `retryPolicy`, `idempotent` |
| `Cache(storage:)` | Memory or disk, ETag support | `cachePolicy` |
| `Timeout(default:)` | Per-request override | `timeout` |
| `Deduplicate(scope:, ttl:)` | GET-only by default | `deduplicate` |

## Annotations → Metadata → Middleware

Annotations set metadata tags on Request. Middleware reads them. Clean separation — annotations describe characteristics, middleware decides behavior.

```
@Authenticated  →  metadata.requiresAuth = true  →  Authenticate middleware adds token
@Retry(...)     →  metadata.retryPolicy = ...     →  Retry middleware wraps in retry
```
