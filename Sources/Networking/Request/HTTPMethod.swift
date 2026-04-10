public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"

    public var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete:
            true
        case .post, .patch:
            false
        }
    }
}
