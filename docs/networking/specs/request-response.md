# Request & Response

## Request

```swift
struct Request: Sendable {
    var method: HTTPMethod
    var path: String
    var headers: [String: String] = [:]
    var query: [URLQueryItem] = []
    var body: Data? = nil
    var metadata: RequestMetadata = RequestMetadata()
}
```

- **path:** Relative path only (e.g., "/users/123"). Macro combines `@Client(base:)` + endpoint path. `NetworkClient` prepends `baseURL`.
- **headers:** `[String: String]` with `HeaderKey` subscript for common headers.
- **query:** `[URLQueryItem]` — already encoded by the time Request is created. Optional params omitted when nil.
- **body:** `Data?` — pre-encoded by macro using configured encoder. `nil` means no body.
- **metadata:** Extensible key-value store for middleware tags. See `request-metadata.md`.

### Builder Pattern

Static factories:

```swift
Request.get("/users/123")
Request.post("/users")
Request.put("/users/123")
Request.delete("/users/123")
Request.patch("/users/123")
```

Modifier chain (each returns a new Request):

```swift
Request.post("/users")
    .header(.contentType, ContentType.applicationJSON.rawValue)
    .header(.custom("X-API-Version"), "2")
    .query("notify", "true")
    .query(encodedItems)            // [URLQueryItem]
    .body(encodedData)
    .contentType(.applicationJSON)
    .authenticated()
    .retry(.exponential(max: 3), on: [.serverError])
    .timeout(30)
    .idempotent()
    .deduplicate()
    .validStatus(200, 404)
    .decoder(CustomDecoder.self)
    .responseMapper(LegacyMapper.self)
    .context(\.rateLimit, 10)
```

Metadata shortcuts (`.authenticated()`, `.retry()`, etc.) set values on `request.metadata` internally.

Var properties are also available for middleware mutation.

### HeaderKey Subscript

```swift
request[header: .authorization] = "Bearer token"   // set
let value = request[header: .accept]                // get
request.headers["X-Custom"] = "value"               // raw string
```

### Path Defaults

`@GET`, `@POST`, etc. default path to `"/"` when omitted. `@Client(base:)` is required.

## Response

```swift
struct Response: Sendable {
    var statusCode: Int
    let headers: [String: String]
    var body: Data

    var isSuccess: Bool { (200...299).contains(statusCode) }
    var isRedirect: Bool { (300...399).contains(statusCode) }
    var isClientError: Bool { (400...499).contains(statusCode) }
    var isServerError: Bool { (500...599).contains(statusCode) }

    subscript(header key: HeaderKey) -> String? {
        headers[key.rawValue]
    }
}
```

- **headers:** `let` — signals read-only. Middleware should not modify response headers. To modify (rare), create a new Response explicitly.
- **body:** `var` — `MapResponse` middleware can transform the body (e.g., envelope unwrapping).
- **body is `Data`, not `Data?`:** Even empty responses (204) have `Data()`. Decoders handle empty data based on return type.

Response is converted from `(Data, URLResponse)` by NetworkClient after transport returns.

## What Request/Response Do NOT Carry

| Concern | Where it lives |
|---|---|
| Base URL | `NetworkClient.baseURL` |
| Default encoder/decoder | `NetworkClient` config |
| Response decoded type | Generic parameter on `NetworkClient.send<T>()` |
| Redirect history | URLSession handles this |
