# Transport

Abstraction over URLSession. NetworkClient calls Transport after the middleware chain. Transport has no knowledge of Request, Response, or RequestMetadata — it works with Foundation types only.

## Protocol

```swift
protocol Transport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
    func bytes(_ request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse)
    func upload(_ request: URLRequest, from data: Data) -> TransportTask
    func download(_ request: URLRequest) -> TransportTask
}
```

## TransportTask

For progress-tracked uploads and downloads:

```swift
struct TransportTask: Sendable {
    var progress: AsyncStream<TransferProgress>
    var response: (Data, URLResponse) { get async throws }
}

struct TransferProgress: Sendable {
    var fractionCompleted: Double
    var totalBytes: Int64?
    var completedBytes: Int64
}
```

Progress and result are separate properties. Caller chooses what to observe:

```swift
// With progress:
for await p in task.progress { updateBar(p.fractionCompleted) }
let (data, response) = try await task.response

// Without progress:
let (data, response) = try await task.response
```

## URLSession Conformance

`send` and `bytes` wrap existing URLSession async methods:

```swift
extension URLSession: Transport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }

    func bytes(_ request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        try await bytes(for: request)
    }
}
```

`upload` and `download` bridge URLSession delegate callbacks into `TransportTask`. This requires an internal delegate wrapper that converts progress updates into the `AsyncStream`.

## Conversion Layer

NetworkClient converts between library types and Foundation types:

```
Request (our type)
    │
    ▼ NetworkClient converts
URLRequest (Foundation)
    │  - baseURL + path → URL
    │  - headers → allHTTPHeaderFields
    │  - query → URL query string
    │  - body → httpBody
    │  - method → httpMethod
    │
    ▼ Transport sends
(Data, URLResponse) (Foundation)
    │
    ▼ NetworkClient converts
Response (our type)
    │  - statusCode from HTTPURLResponse
    │  - headers from allHeaderFields
    │  - body from Data
```

## Why Our Own Transport Protocol

- `URLSession` doesn't bundle body with response — they're separate return values
- `URLResponse` headers are `[AnyHashable: Any]`, not `[String: String]`
- Decouples the library from Foundation for future SwiftNIO support
- Easy to mock in tests — implement Transport with canned responses

## Future: SwiftNIO

For Linux support, a `SwiftNIOTransport` would conform to the same protocol. The library's public API stays identical — only the transport layer changes.
