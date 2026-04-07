# Roadmap

Maps each milestone to the relevant spec sections and key implementation notes.

Detailed plans are written just-in-time when each milestone begins.

## [Foundation] Minimal End-to-End

**Relevant specs:** overview, public-api, request-response, middleware, request-metadata, network-client, transport, errors, macros, encoding (ResponseDecoding/RequestEncoding only), feature-types (HTTPMethod, HeaderKey only), package

**Scope:** `Request`, `Response`, `HTTPMethod`, `HeaderKey`, `RequestMetadata`, `Middleware` protocol, `MiddlewareBuilder`, `Transport` protocol, URLSession conformance, `NetworkClient` (basic send), `NetworkError`, `ResponseDecoding`/`RequestEncoding` protocols, `@Client`/`@GET`/`@POST` macros, `MarkerMacro`, path validation.

**Detailed plan:** [minimal-end-to-end.md](minimal-end-to-end.md)

## [Request] Full HTTP + Parameters

**Relevant specs:** encoding (QueryEncoder), feature-types (HTTPMethod), request-response (query handling), macros (`@PUT`/`@DELETE`/`@PATCH` generation)

**Scope:** `QueryEncoder` with configurable array/bool encoding strategies. Complex type query params (Encodable structs flattened). `.queryEncoder()` modifier on `NetworkClient`. `@Client` macro handles all five HTTP methods.

**Notes:** `QueryEncoder` implements Swift's `Encoder` protocol to walk an `Encodable` and produce `[URLQueryItem]`. Nested types use dot notation. All HTTP method marker macros already exist from Minimal End-to-End — this milestone extends `@Client` code generation to handle them.

## [Metadata] Annotations + RequestMetadata

**Relevant specs:** request-metadata, macros (annotation macros), encoding (`@Encoder`/`@Decoder`/`@ContentType`)

**Scope:** All annotation macros — `@Authenticated`, `@Idempotent`, `@Deduplicate`, `@Retry`, `@Cache`, `@Timeout`, `@Encoder`, `@Decoder`, `@ContentType`, `@Header`, `@Context`. `@Client` macro reads annotations and generates corresponding builder calls. `ContentType` enum. `FormURLEncoder`.

**Notes:** Annotations are marker macros (already trivial). The real work is in `@Client` reading them from the syntax tree and emitting builder calls. The macro doesn't interpret annotation arguments — it copies the syntax into generated code. The compiler type-checks after expansion.

## [Middleware] Middleware Chain

**Relevant specs:** middleware (MiddlewareGroup, built-ins, inline helpers)

**Scope:** `MiddlewareGroup` protocol with `@MiddlewareBuilder` body. Built-in middleware: `Logger`, `Authenticate`, `Retry`, `Timeout`. Inline helpers: `Intercept`, `MapRequest`, `MapResponse`, `OnContext`. `RetryPolicy` + `RetryCondition` types. `MiddlewareBuilder` conditional support (if/else, loops).

**Notes:** `Authenticate` uses actor-based `TokenStore` for concurrent refresh (see middleware.md). `Retry` checks `metadata.retryPolicy`, `metadata.idempotent`, and falls back to `HTTPMethod.isIdempotent`. Middleware errors pass through unwrapped — only library pipeline errors become `NetworkError`.

## [Response] Response Handling

**Relevant specs:** errors (`@ValidStatus`), macros (`@ValidStatus`/`@ResponseMapper`), network-client (Optional handling), encoding (ResponseMapping)

**Scope:** `@ValidStatus` annotation + Optional return type nil mapping. `@ResponseMapper` annotation + `ResponseMapping` protocol. `.responseMapper()` on `NetworkClient` for global envelope unwrapping. `NetworkError` refinement for Optional paths.

**Notes:** When return type is `T?` and status code is in `validStatuses` but body is empty or not decodable, return `nil` instead of throwing. The `@ValidStatus` annotation only sets `metadata.validStatuses` — the validation logic lives in `NetworkClient.send()`.

## [Client] @API Container + Multiple Networks

**Relevant specs:** public-api (`@API`, `@Network`), macros (`@API` implementation), network-client (defaultHeaders)

**Scope:** `@API` macro — simple form `init(network:)` and multi-network form `init(networks:)`. `@Network(\.key)` annotation. `.defaultHeaders()` modifier on `NetworkClient`. Properties with default values skipped in `@API` generation.

**Notes:** `@API` generates init in an extension (preserves memberwise init). The macro reads `networks:` type name and `default:` key path from the attribute. For each property, checks for `@Network` override or uses default. Compiler type-checks the generated key path access after expansion.

## [Middleware] Caching + Deduplication

**Relevant specs:** middleware (Cache, Deduplicate), feature-types (CachePolicy, CacheStorage, ByteCount)

**Scope:** `Cache` middleware with ETag/conditional request support. `CachePolicy`, `CacheStorage`, `ByteCount` types. `@Cache` annotation. `Deduplicate` middleware with shared actor state. `@Deduplicate` annotation.

**Notes:** Cache keys on method + path + query (GET only by default). Stores `Response` with timestamp and ETag. On hit: check TTL, optionally send conditional request (`If-None-Match`). On 304: return cached response. `Deduplicate` uses an actor to track in-flight requests — if identical request is in-flight, await its result instead of sending a new one.

## [Transport] Uploads + Progress

**Relevant specs:** encoding (MultipartFormData, FileData, FormURLEncoder), feature-types (Transfer, TransferProgress), transport (TransportTask, upload/download)

**Scope:** `MultipartFormData` builder (`.field()`, `.file()`). `FileData` type. `Transfer<T>` type with progress stream + async value. `TransportTask`. URLSession delegate bridging for progress. `FormURLEncoder`. Macro detects `MultipartFormData` body type and generates `.encoded()` + `.contentType` instead of JSON encoding.

**Notes:** `Transfer<T>` separates progress (AsyncStream) from result (async throws). Caller can observe progress or just await `.value`. The macro infers download vs upload from HTTP method + `Transfer<T>` return type — no `@Download`/`@Upload` annotation needed. URLSession progress requires bridging delegate callbacks into `AsyncStream`.

## [SSE] SSE

**Relevant specs:** sse

**Scope:** `ServerSentEvent` type. `SSEParser` (consumes `AsyncBytes`, emits events). `NetworkClient.stream()` method. Auto-reconnection with `Last-Event-ID`. Event filtering via `event:` parameter (String or `RawRepresentable<String>`). `SSEEventDecodable` protocol. `@SSEEvents` + `@Event` macros.

**Notes:** SSE lives in core `Networking` module. Parser follows SSE spec: `:` comments skipped, `data:` joins with `\n`, blank line emits event. Reconnection loop: on disconnect, wait `retry` delay, reconnect with `Last-Event-ID` header. `@SSEEvents` generates `SSEEventDecodable` conformance — cases with associated values decode, cases without construct directly.

## [WebSocket] WebSocket

**Relevant specs:** websocket, package (NetworkingWebSocket target)

**Scope:** `NetworkingWebSocket` module. `WebSocketMessage` enum. `WebSocketCloseCode` enum. `WebSocketConnection` struct (closure-based for testability). Typed send/receive extensions. `@WebSocket` macro. `NetworkClient.webSocket()` as extension from the module.

**Notes:** Separate module — users must `import NetworkingWebSocket`. No auto-reconnect (bidirectional protocol can't restore state automatically). Middleware applies to initial HTTP upgrade request only. `WebSocketConnection` uses struct-with-closures pattern for testability — mock by providing custom closures.

## [Utilities] Utilities + Polish

**Relevant specs:** feature-types (pagination), encoding (QueryEncoder config)

**Scope:** `paginate()` and `cursorPaginate()` helper functions. `PaginatedResponse` and `CursorPaginatedResponse` protocols. Remaining edge cases across all modules. Test coverage reporting setup.

**Notes:** Pagination helpers are standalone utility functions, not integrated into the macro system. Users call endpoints manually in the fetch closure. Both return `AsyncThrowingStream<[T], Error>` for incremental consumption.
