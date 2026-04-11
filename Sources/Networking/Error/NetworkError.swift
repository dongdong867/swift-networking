import Foundation

public struct NetworkError: Error, Sendable {
    public let kind: Kind
    public let request: Request
    public let response: Response?

    public init(kind: Kind, request: Request, response: Response?) {
        self.kind = kind
        self.request = request
        self.response = response
    }
}

extension NetworkError {
    public enum Kind: Sendable {
        case invalidStatus(Int)
        case decodingFailed(any Error & Sendable)
        case transportFailed(any Error & Sendable)
        case encodingFailed(any Error & Sendable)
    }
}

// MARK: - Pattern Matching

extension NetworkError {
    public static func ~= (code: Int, error: NetworkError) -> Bool {
        guard case .invalidStatus(let status) = error.kind else { return false }
        return status == code
    }

    public static func ~= <R: RangeExpression<Int>>(range: R, error: NetworkError) -> Bool {
        guard case .invalidStatus(let status) = error.kind else { return false }
        return range.contains(status)
    }
}

// MARK: - Convenience Properties

extension NetworkError {
    public var statusCode: Int? { response?.statusCode }
    public var body: Data? { response?.body }
    public var headers: [HeaderKey: String]? { response?.headers }
    public var isClientError: Bool { response?.isClientError ?? false }
    public var isServerError: Bool { response?.isServerError ?? false }
}

