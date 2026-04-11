import Foundation
import Testing

@testable import Networking

// MARK: - Test Keys

private enum TagKey: RequestMetadataKey {
    static let defaultValue: String = ""
}

// MARK: - Tests

@Suite("Request")
struct RequestTests {
    @Suite("Static Factories")
    struct StaticFactories {
        @Test
        func getFactory() {
            let request = Request.get("/users")

            #expect(request.method == .get)
            #expect(request.path == "/users")
        }

        @Test
        func postFactory() {
            let request = Request.post("/items")

            #expect(request.method == .post)
            #expect(request.path == "/items")
        }

        @Test
        func putFactory() {
            let request = Request.put("/items/1")

            #expect(request.method == .put)
            #expect(request.path == "/items/1")
        }

        @Test
        func deleteFactory() {
            let request = Request.delete("/items/1")

            #expect(request.method == .delete)
            #expect(request.path == "/items/1")
        }

        @Test
        func patchFactory() {
            let request = Request.patch("/items/1")

            #expect(request.method == .patch)
            #expect(request.path == "/items/1")
        }

        @Test
        func factoryDefaultsAreEmpty() {
            let request = Request.get("/users")

            #expect(request.headers.isEmpty)
            #expect(request.query.isEmpty)
            #expect(request.body == nil)
        }
    }

    @Suite("Memberwise Init")
    struct MemberwiseInit {
        @Test
        func fullInit() {
            let body = Data("{}".utf8)
            let request = Request(
                method: .post,
                path: "/items",
                headers: [.contentType: "application/json"],
                query: [URLQueryItem(name: "v", value: "2")],
                body: body,
                metadata: RequestMetadata()
            )

            #expect(request.method == .post)
            #expect(request.path == "/items")
            #expect(request.headers[.contentType] == "application/json")
            #expect(request.query.count == 1)
            #expect(request.body == body)
        }

        @Test
        func defaultsAfterPath() {
            let request = Request(method: .get, path: "/users")

            #expect(request.headers.isEmpty)
            #expect(request.query.isEmpty)
            #expect(request.body == nil)
        }
    }

    @Suite("Acceptance")
    struct Acceptance {
        @Test
        func minimalGetRequest() {
            let request = Request.get("/users")

            #expect(request.method == .get)
            #expect(request.path == "/users")
            #expect(request.headers.isEmpty)
            #expect(request.query.isEmpty)
            #expect(request.body == nil)
            #expect(request.metadata[TagKey.self].isEmpty)
        }

        @Test
        func builderChainingAppliesAllModifications() {
            let body = Data("{}".utf8)
            let request = Request.post("/items")
                .header(.authorization, "Bearer token")
                .query("page", "1")
                .body(body)
                .metadata(TagKey.self, "tagged")

            #expect(request.method == .post)
            #expect(request.path == "/items")
            #expect(request.headers[.authorization] == "Bearer token")
            #expect(request.query.first?.name == "page")
            #expect(request.query.first?.value == "1")
            #expect(request.body == body)
            #expect(request.metadata[TagKey.self] == "tagged")
        }

        @Test
        func builderReturnsNewCopyOriginalUnchanged() {
            let original = Request.get("/users")
            let modified = original.header(.authorization, "Bearer token")

            #expect(original.headers.isEmpty)
            #expect(modified.headers[.authorization] == "Bearer token")
        }

        @Test
        func headerSubscriptGetAndSet() {
            var request = Request.get("/users")
            #expect(request[header: .authorization] == nil)

            request[header: .authorization] = "Bearer token"
            #expect(request[header: .authorization] == "Bearer token")
        }

        @Test
        func threeHeaderWritePaths() {
            let viaBuilder = Request.get("/a")
                .header(.authorization, "token")

            var viaSubscript = Request.get("/a")
            viaSubscript[header: .authorization] = "token"

            var viaRawDict = Request.get("/a")
            viaRawDict.headers[.authorization] = "token"

            #expect(viaBuilder[header: .authorization] == "token")
            #expect(viaSubscript[header: .authorization] == "token")
            #expect(viaRawDict[header: .authorization] == "token")
        }

        @Test
        func pathAcceptsAnyString() {
            let empty = Request.get("")
            let noSlash = Request.get("users")

            #expect(empty.path == "")
            #expect(noSlash.path == "users")
        }
    }
}
