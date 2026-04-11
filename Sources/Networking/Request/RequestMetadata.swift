public protocol RequestMetadataKey {
    associatedtype Value: Sendable
    static var defaultValue: Value { get }
}

public struct RequestMetadata: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    public init() {}

    public subscript<K: RequestMetadataKey>(_ key: K.Type) -> K.Value {
        get { storage[ObjectIdentifier(key)] as? K.Value ?? K.defaultValue }
        set { storage[ObjectIdentifier(key)] = newValue }
    }
}
