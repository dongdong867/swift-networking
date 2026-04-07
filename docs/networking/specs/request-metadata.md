# RequestMetadata

Extensible key-value store for per-endpoint configuration. Same pattern as SwiftUI's `EnvironmentValues`.

## Design

Pure key-value storage — all keys (built-in and custom) use the same mechanism:

```swift
struct RequestMetadata: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    subscript<K: RequestMetadataKey>(key: K.Type) -> K.Value {
        get { storage[ObjectIdentifier(key)] as? K.Value ?? K.defaultValue }
        set { storage[ObjectIdentifier(key)] = newValue }
    }
}

protocol RequestMetadataKey {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}
```

## Built-in Keys

Exposed as computed properties on `RequestMetadata`:

| Property | Type | Default | Set by |
|---|---|---|---|
| `requiresAuth` | `Bool` | `false` | `@Authenticated` |
| `retryPolicy` | `RetryPolicy?` | `nil` | `@Retry` |
| `timeout` | `TimeInterval?` | `nil` | `@Timeout` |
| `idempotent` | `Bool?` | `nil` | `@Idempotent` |
| `deduplicate` | `Bool` | `false` | `@Deduplicate` |
| `cachePolicy` | `CachePolicy?` | `nil` | `@Cache` |
| `validStatuses` | `Set<Int>?` | `nil` | `@ValidStatus` |
| `decoder` | `(any ResponseDecoding.Type)?` | `nil` | `@Decoder` |
| `responseMapper` | `(any ResponseMapping.Type)?` | `nil` | `@ResponseMapper` |

When `nil`, NetworkClient falls back to its own defaults.

Each built-in key follows the pattern:

```swift
enum RequiresAuthKey: RequestMetadataKey {
    static var defaultValue: Bool { false }
}

extension RequestMetadata {
    var requiresAuth: Bool {
        get { self[RequiresAuthKey.self] }
        set { self[RequiresAuthKey.self] = newValue }
    }
}
```

## User Extension

Users extend RequestMetadata with custom keys:

```swift
// 1. Define a key:
enum RateLimitKey: RequestMetadataKey {
    static var defaultValue: Int? { nil }
}

// 2. Add computed property:
extension RequestMetadata {
    var rateLimit: Int? {
        get { self[RateLimitKey.self] }
        set { self[RateLimitKey.self] = newValue }
    }
}

// 3. Use via @Context annotation:
@GET("/search")
@Context(\.rateLimit, 10)
var search: @Sendable (_ query: String) async throws -> SearchResult

// 4. Read in middleware:
OnContext(\.rateLimit) { limit, request in
    await rateLimiter.acquire(limit: limit)
    return request
}
```

## Request Builder Integration

Metadata is set through builder methods on Request, not constructed directly:

```swift
Request.get("/users/123")
    .authenticated()                      // metadata.requiresAuth = true
    .retry(.exponential(max: 3))          // metadata.retryPolicy = ...
    .timeout(30)                          // metadata.timeout = 30
    .context(\.rateLimit, 10)             // metadata[RateLimitKey.self] = 10
```

Users never construct RequestMetadata directly — it's an implementation detail behind the Request builder.
