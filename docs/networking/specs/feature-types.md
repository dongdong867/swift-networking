# Feature Types

## HTTPMethod

```swift
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

extension HTTPMethod {
    var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete: true
        case .post, .patch: false
        }
    }
}
```

Used by `Retry` middleware when `metadata.idempotent` is nil — falls back to method-based inference.

## HeaderKey

```swift
enum HeaderKey: Sendable, Hashable {
    case accept
    case authorization
    case cacheControl
    case contentType
    case userAgent
    case custom(String)

    var rawValue: String { ... }
}
```

Used in:
- Request/Response subscripts: `request[header: .authorization]`
- `@Header` annotation: `@Header(.accept, "application/json")`
- Default headers: `.defaultHeaders([.accept: "application/json"])`

## RetryPolicy + RetryCondition

```swift
struct RetryPolicy: Sendable {
    var strategy: Strategy
    var conditions: [RetryCondition]

    enum Strategy: Sendable {
        case exponential(max: Int, baseDelay: Duration = .seconds(1))
        case fixed(max: Int, delay: Duration)
        case immediate(max: Int)
    }
}

enum RetryCondition: Sendable {
    case serverError        // 500-599
    case timeout            // URLError.timedOut
    case connectionLost     // URLError.networkConnectionLost
    case tooManyRequests    // 429
    case statusCode(Int)    // specific code
}
```

Factory methods:

```swift
RetryPolicy.exponential(max: 3)
RetryPolicy.exponential(max: 3, on: [.serverError, .tooManyRequests])
RetryPolicy.fixed(max: 5, delay: .seconds(2), on: [.tooManyRequests])
```

Default conditions: `[.serverError, .timeout, .connectionLost]`.

## CachePolicy + CacheStorage + ByteCount

```swift
enum CachePolicy: Sendable {
    case returnCacheElseLoad(ttl: Duration)
    case reloadIgnoringCache
    case returnCacheOnly
}

enum CacheStorage: Sendable {
    case memory(limit: ByteCount)
    case disk(directory: URL, limit: ByteCount)
}

struct ByteCount: Sendable {
    var bytes: Int64

    static func megabytes(_ mb: Int64) -> ByteCount
    static func gigabytes(_ gb: Int64) -> ByteCount
}
```

## Transfer + TransferProgress

```swift
struct Transfer<Value: Sendable>: Sendable {
    var progress: AsyncStream<TransferProgress>
    var value: Value { get async throws }
}

struct TransferProgress: Sendable {
    var fractionCompleted: Double
    var totalBytes: Int64?
    var completedBytes: Int64
}
```

Return type signals progress tracking. HTTP method determines direction:
- GET/DELETE + `Transfer<T>` → download
- POST/PUT/PATCH + `Transfer<T>` → upload

No `@Download`/`@Upload` annotation needed.

Usage:

```swift
// With progress:
let transfer = api.files.download("large-file")
Task { for await p in transfer.progress { updateBar(p.fractionCompleted) } }
let data = try await transfer.value

// Without progress:
let data = try await api.files.download("large-file").value
```

## Pagination Utilities

### Offset-based

```swift
func paginate<T>(
    startingAt page: Int = 1,
    _ fetch: @Sendable (Int) async throws -> PaginatedResponse<T>
) -> AsyncThrowingStream<[T], any Error>

protocol PaginatedResponse<Item> {
    associatedtype Item
    var items: [Item] { get }
    var hasNextPage: Bool { get }
}
```

### Cursor-based

```swift
func cursorPaginate<T>(
    _ fetch: @Sendable (String?) async throws -> CursorPaginatedResponse<T>
) -> AsyncThrowingStream<[T], any Error>

protocol CursorPaginatedResponse<Item> {
    associatedtype Item
    var items: [Item] { get }
    var nextCursor: String? { get }
}
```

Usage:

```swift
for try await batch in paginate({ page in
    try await api.users.list(page, 20)
}) {
    allUsers.append(contentsOf: batch)
}
```

Users can always call endpoints manually for custom pagination logic.
