public enum HTTPMethod: String, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"

    public var isIdempotent: Bool {
        switch self {
        case .delete, .get, .put:
            true
        case .patch, .post:
            false
        }
    }
}
