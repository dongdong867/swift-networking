# Public API

## Closure-Based Client Pattern

The primary API is struct-with-closures, inspired by Point-Free's Dependencies pattern. Each API client is a struct with closure properties. Macros generate the live implementation.

```swift
@Client(base: "/users")
struct UserClient {
    @GET("/{id}")
    @Authenticated
    var getUser: @Sendable (_ id: String) async throws -> User

    @POST
    @Authenticated
    var createUser: @Sendable (_ body: CreateUserRequest) async throws -> User

    @DELETE("/{id}")
    @Authenticated
    @Idempotent
    var deleteUser: @Sendable (_ id: String) async throws -> Void
}
```

### Macro Generation

`@Client` generates `init(network: NetworkClient)` in an extension, preserving Swift's memberwise init for testing:

```swift
// Live usage:
let users = UserClient(network: network)
let user = try await users.getUser("123")

// Test usage (memberwise init):
let mock = UserClient(
    getUser: { _ in User(id: "1", name: "Test") },
    createUser: { _ in fatalError() },
    deleteUser: { _ in fatalError() }
)
```

## Parameter Inference Rules

Three rules, applied in order:

1. **Name matches `{placeholder}` in path** → Path parameter
2. **Name is `body`** → Request body
3. **Everything else** → Query parameter

Query parameter details:
- Primitive types (Int, String, Bool, Double) → encoded directly
- Optional → omitted when nil
- Array → encoded per QueryEncoder strategy
- Complex type (Encodable struct) → flattened via QueryEncoder

## Return Type → Behavior

| Return Type | Behavior |
|---|---|
| `async throws -> T` (Decodable) | Single request, decode JSON response |
| `async throws -> T?` | Nilable (with @ValidStatus for 404 → nil) |
| `async throws -> Void` | Validate status, skip decoding |
| `async throws -> Data` | Validate status, return raw bytes |
| `async throws -> String` | Validate status, decode as UTF-8 |
| `-> AsyncThrowingStream<T, Error>` | SSE streaming |
| `-> Transfer<T>` | Upload/download with progress |

## @API Container

Groups multiple clients with optional multi-network support:

```swift
// Single network:
@API
struct AppAPI {
    var users: UserClient
    var posts: PostClient
}
let api = AppAPI(network: network)

// Multiple networks:
@API(networks: AppNetworks.self, default: \.main)
struct AppAPI {
    var users: UserClient
    @Network(\.auth) var auth: AuthClient
    @Network(\.cdn) var uploads: UploadClient
}
let api = AppAPI(networks: appNetworks)
```

Properties with default values are skipped (not treated as clients). Both forms preserve the memberwise init for manual wiring.

## NetworkClient Configuration

```swift
let network = NetworkClient(baseURL: "https://api.example.com") {
    Logger()
    Authenticate { try await tokenStore.current }
    Retry(.exponential(max: 3))
    Cache(storage: .memory(limit: .megabytes(50)))
}
.defaultHeaders([.accept: "application/json", .userAgent: "MyApp/1.0"])
.defaultDecoder(JSONDecoder())
.defaultEncoder(JSONEncoder())
.responseMapper(EnvelopeUnwrapper.self)
```

Sensible defaults: JSON encoder/decoder, URLSession transport, no middleware. Minimal construction for simple cases:

```swift
let network = NetworkClient(baseURL: "https://api.example.com")
```
