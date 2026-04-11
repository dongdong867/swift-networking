import Foundation

public struct Response: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [HeaderKey: String]
    public var body: Data

    public init(statusCode: Int, headers: [HeaderKey: String], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public subscript(header key: HeaderKey) -> String? {
        headers[key]
    }

    public var isSuccess: Bool { (200...299).contains(statusCode) }
    public var isRedirect: Bool { (300...399).contains(statusCode) }
    public var isClientError: Bool { (400...499).contains(statusCode) }
    public var isServerError: Bool { (500...599).contains(statusCode) }
}
