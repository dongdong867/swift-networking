import Foundation
import Testing

@testable import Networking

@Suite("Response")
struct ResponseTests {
    @Suite("Construction")
    struct Construction {
        @Test
        func initSetsAllProperties() {
            let headers: [HeaderKey: String] = [
                .contentType: "application/json",
                .authorization: "Bearer token",
            ]
            let body = Data("hello".utf8)

            let response = Response(
                statusCode: 200,
                headers: headers,
                body: body
            )

            #expect(response.statusCode == 200)
            #expect(response.headers == headers)
            #expect(response.body == body)
        }
    }
    @Suite("Body")
    struct Body {
        @Test
        func bodyIsNonOptionalData() {
            let response = Response(
                statusCode: 204,
                headers: [:],
                body: Data()
            )

            let body: Data = response.body
            #expect(body.isEmpty)
        }

        @Test
        func bodyIsMutable() {
            var response = Response(
                statusCode: 200,
                headers: [:],
                body: Data()
            )

            response.body = Data("transformed".utf8)
            #expect(response.body == Data("transformed".utf8))
        }
    }
    @Suite("Status Categories")
    struct StatusCategories {
        @Test(arguments: [200, 201, 250, 299])
        func isSuccess(statusCode: Int) {
            #expect(Response(statusCode: statusCode, headers: [:], body: Data()).isSuccess)
        }

        @Test(arguments: [300, 301, 350, 399])
        func isRedirect(statusCode: Int) {
            #expect(Response(statusCode: statusCode, headers: [:], body: Data()).isRedirect)
        }

        @Test(arguments: [400, 404, 450, 499])
        func isClientError(statusCode: Int) {
            #expect(Response(statusCode: statusCode, headers: [:], body: Data()).isClientError)
        }

        @Test(arguments: [500, 503, 550, 599])
        func isServerError(statusCode: Int) {
            #expect(Response(statusCode: statusCode, headers: [:], body: Data()).isServerError)
        }

        @Test(arguments: [0, 199, 600])
        func outsideKnownRangesMatchNothing(statusCode: Int) {
            let response = Response(statusCode: statusCode, headers: [:], body: Data())
            #expect(
                !response.isSuccess && !response.isRedirect && !response.isClientError
                    && !response.isServerError)
        }

        @Test(arguments: [200, 300, 400, 500])
        func categoriesAreMutuallyExclusive(statusCode: Int) {
            let response = Response(statusCode: statusCode, headers: [:], body: Data())
            let count = [
                response.isSuccess, response.isRedirect, response.isClientError,
                response.isServerError,
            ]
            .filter { $0 }.count
            #expect(count == 1)
        }
    }
    @Suite("Header Subscript")
    struct HeaderSubscript {
        @Test
        func accessExistingHeader() {
            let response = Response(
                statusCode: 200,
                headers: [.contentType: "application/json"],
                body: Data()
            )

            #expect(response[header: .contentType] == "application/json")
        }

        @Test
        func accessMissingHeaderReturnsNil() {
            let response = Response(
                statusCode: 200,
                headers: [:],
                body: Data()
            )

            #expect(response[header: .contentType] == nil)
        }
    }
    @Suite("Equatable")
    struct EquatableConformance {
        @Test
        func equalResponses() {
            let a = Response(
                statusCode: 200, headers: [.contentType: "text/plain"], body: Data("ok".utf8))
            let b = Response(
                statusCode: 200, headers: [.contentType: "text/plain"], body: Data("ok".utf8))
            #expect(a == b)
        }

        @Test
        func differentStatusCodeNotEqual() {
            let a = Response(statusCode: 200, headers: [:], body: Data())
            let b = Response(statusCode: 201, headers: [:], body: Data())
            #expect(a != b)
        }

        @Test
        func differentHeadersNotEqual() {
            let a = Response(statusCode: 200, headers: [.contentType: "text/plain"], body: Data())
            let b = Response(
                statusCode: 200, headers: [.contentType: "application/json"], body: Data())
            #expect(a != b)
        }

        @Test
        func differentBodyNotEqual() {
            let a = Response(statusCode: 200, headers: [:], body: Data("a".utf8))
            let b = Response(statusCode: 200, headers: [:], body: Data("b".utf8))
            #expect(a != b)
        }
    }
}
