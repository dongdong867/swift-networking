public struct HeaderKey: Sendable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }

    public func hash(into hasher: inout Hasher) {
        rawValue.lowercased().hash(into: &hasher)
    }
}

extension HeaderKey {
    public static let accept = HeaderKey("Accept")
    public static let authorization = HeaderKey("Authorization")
    public static let cacheControl = HeaderKey("Cache-Control")
    public static let contentType = HeaderKey("Content-Type")
    public static let userAgent = HeaderKey("User-Agent")
}
