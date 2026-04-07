# Macros

## Inventory (24 total)

### Core macros (generate code)
- `@Client(base:)` — `@attached(extension)` — generates `init(network:)`
- `@API` / `@API(networks:default:)` — `@attached(extension)` — generates container init
- `@SSEEvents` — `@attached(extension)` — generates `SSEEventDecodable` conformance

### Marker macros (metadata only — shared `MarkerMacro` implementation)
- HTTP methods: `@GET`, `@POST`, `@PUT`, `@DELETE`, `@PATCH`, `@SSE`, `@WebSocket`
- Annotations: `@Authenticated`, `@Idempotent`, `@Deduplicate`
- Config: `@Retry`, `@Cache`, `@Timeout`, `@Encoder`, `@Decoder`, `@ContentType`, `@Header`
- Response: `@ValidStatus`, `@ResponseMapper`
- Extensibility: `@Context`, `@Network`
- SSE: `@Event`

All marker macros share one implementation that returns empty. They exist only as metadata for `@Client`, `@API`, and `@SSEEvents` to read from the syntax tree.

## @Client Implementation

**Role:** `@attached(extension, names: named(init))`

### What it reads

1. `base` argument from `@Client(base: "/users")`
2. Each `var` member with an HTTP method attribute
3. Per member: HTTP method + path, all annotation attributes, closure type signature

### What it generates

An extension with `init(network: NetworkClient)`:

```swift
extension UserClient {
    init(network: NetworkClient) {
        self.init(
            getUser: { id in
                try await network.send(
                    Request.get("/users/\(id)")
                        .authenticated(),
                    as: User.self
                )
            },
            createUser: { body in
                try await network.send(
                    Request.post("/users")
                        .header(.contentType, ContentType.applicationJSON.rawValue)
                        .body(try network.defaultEncoder.encode(body))
                        .authenticated(),
                    as: User.self
                )
            }
        )
    }
}
```

### Generation rules

**Path construction:** Combine base + endpoint path, interpolate path parameters.

**Body encoding by content type/body type:**
- Default `Encodable` → `network.defaultEncoder.encode(body)` + JSON content type
- `@ContentType(.formURLEncoded)` → `FormURLEncoder().encode(body)`
- `@Encoder(Custom.self)` → `Custom().encode(body)`
- `MultipartFormData` body type → `body.encoded()` + `body.contentType` (auto-detected)
- `String` body with `@ContentType(.text)` → `Data(body.utf8)`
- `Data` body with `@ContentType(.octetStream)` → raw Data

**Network method by return type:**
- `async throws -> T` → `network.send(request, as: T.self)`
- `async throws -> T?` → `network.send(request, as: T?.self)`
- `async throws -> Void` → `network.send(request)`
- `async throws -> Data` → `network.data(request)`
- `async throws -> String` → `network.string(request)`
- `-> AsyncThrowingStream<T, Error>` → `network.stream(request, as: T.self)`
- `-> Transfer<T>` → `network.transfer(request, as: T.self)`

**Annotations → builder calls:** The macro reads annotation syntax and re-emits as builder method calls. It doesn't interpret the arguments — the compiler type-checks the generated code.

## @API Implementation

**Role:** `@attached(extension, names: named(init))`

**Simple form:** Generates `init(network: NetworkClient)`:
```swift
extension AppAPI {
    init(network: NetworkClient) {
        self.init(
            users: UserClient(network: network),
            posts: PostClient(network: network)
        )
    }
}
```

**Multi-network form:** Reads `networks:` type and `default:` key path. `@Network(\.key)` overrides per property:
```swift
extension AppAPI {
    init(networks: AppNetworks) {
        self.init(
            users: UserClient(network: networks.main),      // default
            auth: AuthClient(network: networks.auth),        // @Network(\.auth)
            uploads: UploadClient(network: networks.cdn)     // @Network(\.cdn)
        )
    }
}
```

Properties with default values are skipped.

## @SSEEvents Implementation

**Role:** `@attached(extension, names: named(init))`

Generates `SSEEventDecodable` conformance from enum with `@Event` annotations. See `sse.md`.

## Path Validation (compile-time)

### @Client(base:)
- Must start with `/`
- No trailing slash (stripped with warning)
- No spaces or invalid URL characters
- No query string
- No placeholders

### @GET(path) etc.
- Must start with `/` (default `/` when omitted)
- `{placeholder}` names must be valid Swift identifiers
- No unclosed/nested braces
- No spaces
- No query string

## Error Diagnostics

| Scenario | Severity | Message |
|---|---|---|
| Multiple HTTP methods on one var | Error | Multiple HTTP method annotations on '{name}'. Use exactly one. |
| Path `{userId}` with no matching param | Error | Path parameter '{userId}' has no matching parameter. Found 'id' — did you mean '{id}'? |
| Unnamed closure params `(String)` | Error | Closure parameters must have names. Use: (_ id: String) |
| `@Client` on class/enum | Error | @Client can only be applied to structs. |
| `@Client(base: "")` | Error | Base path cannot be empty. |
| `@SSE` without `AsyncThrowingStream` return | Error | @SSE requires return type AsyncThrowingStream<T, Error>. |
| Non-closure type with HTTP annotation | Error | Endpoint '{name}' must have a closure type. |
| Computed property with HTTP annotation | Error | Endpoint '{name}' must be a stored property. |
| `@Network` without `@API(networks:)` | Error | @Network requires @API with 'networks' parameter. |
| `@API(networks:)` without `default:` | Error | @API with 'networks' requires 'default' parameter. |
| Annotations without HTTP method | Warning | Property '{name}' has annotations but no HTTP method. |
| `let` endpoint | Warning | Endpoint '{name}' is 'let'. Use 'var' for mock overrides. |
| GET with body param | Warning | GET request with 'body' parameter is uncommon. |
| `@ValidStatus(404)` on non-optional | Warning | @ValidStatus(404) on non-optional '{Type}': 404 will throw if body can't be decoded. Did you mean '{Type}?'? |
| Complex type not named body on POST | Warning | Complex type '{Type}' on POST will be encoded as query params. If this should be the body, rename to 'body'. |
| Base path missing leading `/` | Warning | Base path should start with '/'. Interpreting as '/{path}'. |
