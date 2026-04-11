public protocol RequestMetadataKey {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}
