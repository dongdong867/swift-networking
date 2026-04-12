public struct ContentType: Sendable, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - Standard Content Types

extension ContentType {
    public static let applicationJSON = ContentType(rawValue: "application/json")
    public static let formURLEncoded = ContentType(rawValue: "application/x-www-form-urlencoded")
    public static let text = ContentType(rawValue: "text/plain")
    public static let octetStream = ContentType(rawValue: "application/octet-stream")
}
