import Foundation

public struct RequestEncoding: Sendable {
    public let contentType: ContentType

    private let _encode: @Sendable (any Encodable) throws -> Data

    public init(contentType: ContentType, encode: @escaping @Sendable (any Encodable) throws -> Data) {
        self.contentType = contentType
        self._encode = encode
    }

    public func encode(_ value: any Encodable) throws -> Data {
        try _encode(value)
    }
}

// MARK: - JSON

extension RequestEncoding {
    public static let json = Self.json(JSONEncoder())

    public static func json(_ encoder: JSONEncoder) -> Self {
        Self(contentType: .applicationJSON) { value in
            try encoder.encode(value)
        }
    }

    public static func json(configure: (JSONEncoder) -> Void) -> Self {
        let encoder = JSONEncoder()
        configure(encoder)
        return .json(encoder)
    }
}
