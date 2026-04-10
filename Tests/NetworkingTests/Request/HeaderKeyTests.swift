import Testing

@testable import Networking

@Suite("HeaderKey")
struct HeaderKeyTests {
    @Suite("Built-in Keys")
    struct BuiltInKeys {
        @Test
        func accept() {
            #expect(HeaderKey.accept.rawValue == "Accept")
        }

        @Test
        func authorization() {
            #expect(HeaderKey.authorization.rawValue == "Authorization")
        }

        @Test
        func cacheControl() {
            #expect(HeaderKey.cacheControl.rawValue == "Cache-Control")
        }

        @Test
        func contentType() {
            #expect(HeaderKey.contentType.rawValue == "Content-Type")
        }

        @Test
        func userAgent() {
            #expect(HeaderKey.userAgent.rawValue == "User-Agent")
        }
    }

    @Suite("Custom Keys")
    struct CustomKeys {
        @Test
        func customKeyPreservesRawValue() {
            let key = HeaderKey("X-Request-ID")
            #expect(key.rawValue == "X-Request-ID")
        }
    }

    @Suite("Case Insensitivity")
    struct CaseInsensitivity {
        @Test
        func equalityIsCaseInsensitive() {
            let upper = HeaderKey("Content-Type")
            let lower = HeaderKey("content-type")
            #expect(upper == lower)
        }

        @Test
        func hashValueIsCaseInsensitive() {
            let upper = HeaderKey("Content-Type")
            let lower = HeaderKey("content-type")
            #expect(upper.hashValue == lower.hashValue)
        }

        @Test
        func rawValuePreservesOriginalCasing() {
            let upper = HeaderKey("Content-Type")
            let lower = HeaderKey("content-type")
            #expect(upper.rawValue == "Content-Type")
            #expect(lower.rawValue == "content-type")
        }

        @Test
        func deduplicatesInSet() {
            let set: Set<HeaderKey> = [
                HeaderKey("Content-Type"),
                HeaderKey("content-type"),
            ]
            #expect(set.count == 1)
        }
    }
}
