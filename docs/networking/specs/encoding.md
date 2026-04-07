# Encoding & Content Types

## Protocols

```swift
protocol ResponseDecoding: Sendable {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

protocol RequestEncoding: Sendable {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

protocol ResponseMapping: Sendable {
    func map(_ data: Data) throws -> Data
}

extension JSONDecoder: ResponseDecoding {}
extension JSONEncoder: RequestEncoding {}
```

Users plug in custom encoders/decoders without subclassing.

## ContentType

```swift
enum ContentType: Sendable {
    case applicationJSON
    case formURLEncoded
    case multipartFormData(boundary: String)
    case text
    case xml
    case octetStream
    case custom(String)

    var rawValue: String { ... }
}
```

## Body Encoding by Type and Annotation

| Body type | Annotation | Encoding |
|---|---|---|
| `Encodable` | None or `@ContentType(.applicationJSON)` | `network.defaultEncoder.encode(body)` + JSON content type |
| `Encodable` | `@ContentType(.formURLEncoded)` | `FormURLEncoder().encode(body)` + form content type |
| `Encodable` | `@Encoder(Custom.self)` | `Custom().encode(body)` |
| `MultipartFormData` | None (inferred from type) | `body.encoded()` + `body.contentType` |
| `String` | `@ContentType(.text)` | `Data(body.utf8)` + text content type |
| `Data` | `@ContentType(.octetStream)` | Raw Data + octet-stream content type |

`@ContentType(.multipartFormData)` is not needed — the macro detects `MultipartFormData` body type automatically.

## Response Decoding

Default: `NetworkClient.defaultDecoder` (JSONDecoder).

Per-endpoint override: `@Decoder(CustomDecoder.self)` sets `metadata.decoder`.

`NetworkClient.send()` uses `metadata.decoder ?? defaultDecoder`.

## Response Mapping

For envelope unwrapping or response transformation:

- **Global:** `NetworkClient.responseMapper(EnvelopeUnwrapper.self)` or `MapResponse` middleware
- **Per-endpoint:** `@ResponseMapper(LegacyMapper.self)` sets `metadata.responseMapper`

Applied after status validation, before decoding.

## QueryEncoder

Encodes `Encodable` types into `[URLQueryItem]` for complex query parameters:

```swift
struct QueryEncoder: Sendable {
    var arrayEncoding: ArrayEncoding = .repeatKey
    var boolEncoding: BoolEncoding = .literal

    enum ArrayEncoding: Sendable {
        case repeatKey        // ids=1&ids=2
        case bracketed        // ids[]=1&ids[]=2
        case commaSeparated   // ids=1,2
    }

    enum BoolEncoding: Sendable {
        case literal    // true/false
        case numeric    // 1/0
    }

    func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem]
}
```

Flattens struct properties into key-value pairs. Optional properties with nil values are omitted.

Configurable on NetworkClient:

```swift
NetworkClient(baseURL: "...")
    .queryEncoder(QueryEncoder(arrayEncoding: .bracketed))
```

## MultipartFormData

Builder pattern for multipart request bodies:

```swift
struct MultipartFormData: Sendable {
    let boundary: String

    func field(_ name: String, _ value: String) -> MultipartFormData
    func file(_ name: String, data: Data, fileName: String, mimeType: String) -> MultipartFormData

    func encoded() -> Data
    var contentType: ContentType { .multipartFormData(boundary: boundary) }
}
```

```swift
let form = MultipartFormData()
    .field("name", "John")
    .field("bio", "Swift developer")
    .file("avatar", data: imageData, fileName: "avatar.jpg", mimeType: "image/jpeg")
```

## FileData

For typed file references:

```swift
struct FileData: Sendable {
    var data: Data
    var fileName: String
    var mimeType: String
}
```

## FormURLEncoder

Encodes `Encodable` into `application/x-www-form-urlencoded` body format:

```swift
struct FormURLEncoder: RequestEncoding {
    func encode<T: Encodable>(_ value: T) throws -> Data
}
```

Used when `@ContentType(.formURLEncoded)` is set.
