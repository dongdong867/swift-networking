import Testing

@testable import Networking

@Suite("HTTPMethod")
struct HTTPMethodTests {

    @Suite("Raw Values")
    struct RawValues {

        @Test func get() {
            #expect(HTTPMethod.get.rawValue == "GET")
        }

        @Test func post() {
            #expect(HTTPMethod.post.rawValue == "POST")
        }

        @Test func put() {
            #expect(HTTPMethod.put.rawValue == "PUT")
        }

        @Test func delete() {
            #expect(HTTPMethod.delete.rawValue == "DELETE")
        }

        @Test func patch() {
            #expect(HTTPMethod.patch.rawValue == "PATCH")
        }
    }

    @Suite("Idempotency")
    struct Idempotency {

        @Test func getIsIdempotent() {
            #expect(HTTPMethod.get.isIdempotent == true)
        }

        @Test func putIsIdempotent() {
            #expect(HTTPMethod.put.isIdempotent == true)
        }

        @Test func deleteIsIdempotent() {
            #expect(HTTPMethod.delete.isIdempotent == true)
        }

        @Test func postIsNotIdempotent() {
            #expect(HTTPMethod.post.isIdempotent == false)
        }

        @Test func patchIsNotIdempotent() {
            #expect(HTTPMethod.patch.isIdempotent == false)
        }
    }
}
