import Testing

@testable import Networking

// MARK: - Test Keys

private enum StringKey: RequestMetadataKey {
    static let defaultValue: String = ""
}

private enum IntKey: RequestMetadataKey {
    static let defaultValue: Int = 0
}

private enum PriorityKey: RequestMetadataKey {
    static let defaultValue: Priority = .normal
}

private enum Priority: Sendable {
    case low
    case normal
    case high
}

// MARK: - Tests

@Suite("RequestMetadata")
struct RequestMetadataTests {
    @Suite("Subscript Read")
    struct SubscriptRead {
        @Test
        func returnsDefaultValueWhenNoValueSet() {
            let metadata = RequestMetadata()
            #expect(metadata[StringKey.self] == "")
        }

        @Test
        func returnsDefaultValueForDifferentTypes() {
            let metadata = RequestMetadata()
            #expect(metadata[IntKey.self] == 0)
            #expect(metadata[PriorityKey.self] == .normal)
        }
    }

    @Suite("Subscript Write")
    struct SubscriptWrite {
        @Test
        func setAndReadBack() {
            var metadata = RequestMetadata()
            metadata[StringKey.self] = "hello"
            #expect(metadata[StringKey.self] == "hello")
        }

        @Test
        func overwriteReturnsLatestValue() {
            var metadata = RequestMetadata()
            metadata[StringKey.self] = "hello"
            metadata[StringKey.self] = "world"
            #expect(metadata[StringKey.self] == "world")
        }
    }

    @Suite("Acceptance")
    struct Acceptance {
        @Test
        func endToEnd() {
            var metadata = RequestMetadata()

            // AC2: Empty metadata returns default
            #expect(metadata[StringKey.self] == "")
            #expect(metadata[IntKey.self] == 0)

            // AC2: Set and read back
            metadata[StringKey.self] = "hello"
            #expect(metadata[StringKey.self] == "hello")

            // AC7: Setting one key doesn't affect another
            metadata[IntKey.self] = 42
            #expect(metadata[StringKey.self] == "hello")
            #expect(metadata[IntKey.self] == 42)

            // Overwrite: last write wins
            metadata[StringKey.self] = "world"
            #expect(metadata[StringKey.self] == "world")

            // AC4: Custom key definition pattern
            metadata[PriorityKey.self] = .high
            #expect(metadata[PriorityKey.self] == .high)

            // AC5: Type safety — return type is the key's Value type
            let _: String = metadata[StringKey.self]
            let _: Int = metadata[IntKey.self]
            let _: Priority = metadata[PriorityKey.self]
        }
    }
}
