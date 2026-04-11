import Foundation

public struct Request: Sendable {
    public let method: HTTPMethod
    public let path: String
    public var headers: [HeaderKey: String]
    public var query: [URLQueryItem]
    public var body: Data?
    public var metadata: RequestMetadata

    public init(
        method: HTTPMethod,
        path: String,
        headers: [HeaderKey: String] = [:],
        query: [URLQueryItem] = [],
        body: Data? = nil,
        metadata: RequestMetadata = RequestMetadata()
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.query = query
        self.body = body
        self.metadata = metadata
    }
}

extension Request {
    public static func get(_ path: String) -> Request {
        Request(method: .get, path: path)
    }

    public static func post(_ path: String) -> Request {
        Request(method: .post, path: path)
    }

    public static func put(_ path: String) -> Request {
        Request(method: .put, path: path)
    }

    public static func delete(_ path: String) -> Request {
        Request(method: .delete, path: path)
    }

    public static func patch(_ path: String) -> Request {
        Request(method: .patch, path: path)
    }
}

// MARK: - Builders

extension Request {
    public func header(_ key: HeaderKey, _ value: String) -> Request {
        self
    }

    public func query(_ name: String, _ value: String) -> Request {
        self
    }

    public func body(_ body: Data) -> Request {
        self
    }

    public func metadata<K: RequestMetadataKey>(_ key: K.Type, _ value: K.Value) -> Request {
        self
    }
}

// MARK: - Header Subscript

extension Request {
    public subscript(header key: HeaderKey) -> String? {
        get { nil }
        set {}
    }
}
