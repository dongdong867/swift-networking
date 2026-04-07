# Error Types

## Design

Single struct with a `Kind` enum. Carries full context (request, response) and supports Swift pattern matching on status codes.

```swift
struct NetworkError: Error, Sendable {
    var kind: Kind
    var request: Request
    var response: Response?

    enum Kind: Sendable {
        case invalidStatus(Int)
        case decodingFailed(any Error & Sendable)
        case transportFailed(any Error & Sendable)
        case encodingFailed(any Error & Sendable)
    }
}
```

## Error Sources

| Kind | When | Has response? |
|---|---|---|
| `.invalidStatus(code)` | Status code not in valid set (default 200-299) | Yes |
| `.decodingFailed(error)` | Response body can't decode as expected type | Yes |
| `.transportFailed(error)` | Network failure, timeout, DNS, etc. | No |
| `.encodingFailed(error)` | Request body can't be encoded | No |

## Pattern Matching

Switch on `error.kind` with range patterns:

```swift
do {
    let user = try await api.users.getUser("123")
} catch {
    switch error.kind {
    case .invalidStatus(404):
        showNotFound()
    case .invalidStatus(429):
        let retryAfter = error[header: .custom("Retry-After")]
        showRateLimited(retryAfter)
    case .invalidStatus(400...499):
        let message = error.decoded(as: APIError.self)?.message
        showError(message ?? "Client error")
    case .invalidStatus(500...):
        showServerError()
    case .transportFailed:
        showOffline()
    case .decodingFailed:
        log("Bad response: \(String(data: error.body ?? Data(), encoding: .utf8) ?? "")")
        showGenericError()
    case .encodingFailed:
        showGenericError()
    }
}
```

## Convenience Properties

```swift
extension NetworkError {
    var statusCode: Int? {
        if case .invalidStatus(let code) = kind { code } else { nil }
    }
    var body: Data? { response?.body }
    var headers: [String: String]? { response?.headers }

    var isHTTPError: Bool { ... }
    var isClientError: Bool { statusCode.map { (400...499).contains($0) } ?? false }
    var isServerError: Bool { statusCode.map { (500...599).contains($0) } ?? false }
    var isTransportError: Bool { ... }
    var isDecodingError: Bool { ... }
    var isRetryable: Bool { isServerError || isTransportError }

    subscript(header key: HeaderKey) -> String? { response?[header: key] }

    func decoded<T: Decodable>(as type: T.Type) -> T? {
        guard let body else { return nil }
        return try? JSONDecoder().decode(type, from: body)
    }

    var underlyingError: (any Error & Sendable)? {
        switch kind {
        case .invalidStatus: nil
        case .decodingFailed(let e): e
        case .transportFailed(let e): e
        case .encodingFailed(let e): e
        }
    }
}
```

## Test Factory Methods

```swift
extension NetworkError {
    static func http(statusCode: Int, body: Data = Data()) -> NetworkError {
        NetworkError(
            kind: .invalidStatus(statusCode),
            request: Request(method: .get, path: "/mock"),
            response: Response(statusCode: statusCode, headers: [:], body: body)
        )
    }

    static func transportError(_ error: any Error & Sendable) -> NetworkError {
        NetworkError(
            kind: .transportFailed(error),
            request: Request(method: .get, path: "/mock"),
            response: nil
        )
    }
}
```

## Status Validation

Default: 200-299. Override with `@ValidStatus(codes)`.

For Optional return types: if status code is valid but body is empty or not decodable, return `nil` instead of throwing. This is how `@ValidStatus(200, 404)` + `User?` works.
