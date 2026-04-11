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
}
