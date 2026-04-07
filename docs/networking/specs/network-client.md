# NetworkClient

The central type that holds configuration, chains middleware, and sends requests.

## Shape

```swift
struct NetworkClient: Sendable {
    var baseURL: String
    var middleware: [any Middleware]
    var transport: any Transport
    var defaultHeaders: [String: String]
    var defaultDecoder: any ResponseDecoding
    var defaultEncoder: any RequestEncoding
    var defaultResponseMapper: (any ResponseMapping.Type)?
}
```

Struct (value type). Middleware instances can hold reference-type state (actors for deduplication, caches) — copying the array is cheap.

## Construction

Result builder for middleware, modifier chain for configuration:

```swift
let network = NetworkClient(baseURL: "https://api.example.com") {
    Logger()
    Authenticate { try await tokenStore.current }
    Retry(.exponential(max: 3))
}
.defaultHeaders([.accept: "application/json", .userAgent: "MyApp/1.0"])
.defaultDecoder(JSONDecoder())
.defaultEncoder(JSONEncoder())
.responseMapper(EnvelopeUnwrapper.self)
```

Sensible defaults (JSON, no middleware, URLSession transport):

```swift
let network = NetworkClient(baseURL: "https://api.example.com")
```

Modifier chain returns new NetworkClient (immutable, functional style).

## Send Methods

| Method | Returns | Use case |
|---|---|---|
| `send<T: Decodable>(Request, as: T.Type)` | `T` | Decodable response |
| `send(Request)` | `Void` | No response body |
| `data(Request)` | `Data` | Raw bytes |
| `string(Request)` | `String` | UTF-8 text |
| `stream<T: Decodable>(Request, as: T.Type)` | `AsyncThrowingStream<T, Error>` | SSE |
| `transfer<T: Decodable>(Request, as: T.Type)` | `Transfer<T>` | Progress tracking |

The macro picks the method based on the endpoint's return type.

## Internal Flow

Every send method follows the same pipeline:

```
1. Apply default headers (request headers take precedence over defaults)
2. Run middleware chain (onion pattern)
3. Transport converts Request → URLRequest, sends, returns Response
4. Validate status code (metadata.validStatuses ?? 200...299)
5. Apply response mapper (metadata.responseMapper ?? defaultResponseMapper)
6. Decode body (metadata.decoder ?? defaultDecoder)
7. Return decoded value
```

### Special Type Handling

| Type | Step 6 behavior |
|---|---|
| `T: Decodable` | Decode using configured decoder |
| `T?` (Optional) | Try decode; if body is empty or decoding fails on valid status → return nil |
| `Void` | Skip decoding |
| `Data` | Return raw body |
| `String` | Decode body as UTF-8 |

### SSE Stream

`stream()` uses a different transport method:

```
1. Apply default headers + middleware (initial HTTP request)
2. transport.bytes(urlRequest) → AsyncBytes
3. SSEParser.events(from: bytes) → ServerSentEvent stream
4. Decode or route (SSEEventDecodable or plain Decodable)
5. Auto-reconnect with Last-Event-ID on disconnect
```

### Transfer (Progress)

`transfer()` uses progress-capable transport:

```
1. Apply default headers + middleware (initial HTTP request)
2. transport.upload/download(urlRequest) → TransportTask
3. Wrap into Transfer<T>(progress: ..., value: { validate + decode })
```

## Multiple Networks

Different backends use separate NetworkClient instances:

```swift
struct AppNetworks {
    let main: NetworkClient
    let auth: NetworkClient
    let cdn: NetworkClient
}
```

The `@API` container wires clients to their networks. See `public-api.md`.
