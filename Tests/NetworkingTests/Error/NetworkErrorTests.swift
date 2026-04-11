import Foundation
import Testing

@testable import Networking

@Suite("NetworkError")
struct NetworkErrorTests {

    // MARK: - Factories

    static func httpError(statusCode: Int) -> NetworkError {
        NetworkError(
            kind: .invalidStatus(statusCode),
            request: .get("/"),
            response: Response(statusCode: statusCode, headers: [:], body: Data())
        )
    }

    static func transportError(_ error: some Error & Sendable) -> NetworkError {
        NetworkError(
            kind: .transportFailed(error),
            request: .get("/"),
            response: nil
        )
    }

    @Suite("Error Structure")
    struct ErrorStructure {
        @Test("carries kind, request, and response")
        func errorCarriesAllFields() {
            let request = Request.get("/test")
            let response = Response(statusCode: 500, headers: [:], body: Data())
            let error = NetworkError(
                kind: .invalidStatus(500),
                request: request,
                response: response
            )

            #expect(error.request.path == "/test")
            #expect(error.response?.statusCode == 500)
        }

        @Test("response is nil for transport failures")
        func responseNilForTransportFailure() {
            let request = Request.get("/test")
            let underlying = URLError(.notConnectedToInternet)
            let error = NetworkError(
                kind: .transportFailed(underlying),
                request: request,
                response: nil
            )

            #expect(error.response == nil)
        }

        @Test("response is nil for encoding failures")
        func responseNilForEncodingFailure() {
            let request = Request.post("/test")
            let underlying = URLError(.cannotDecodeContentData)
            let error = NetworkError(
                kind: .encodingFailed(underlying),
                request: request,
                response: nil
            )

            #expect(error.response == nil)
        }
    }

    @Suite("Kind Enum Cases")
    struct KindEnumCases {
        @Test("invalidStatus carries status code")
        func invalidStatus() {
            let kind = NetworkError.Kind.invalidStatus(404)
            if case .invalidStatus(let code) = kind {
                #expect(code == 404)
            } else {
                Issue.record("Expected .invalidStatus")
            }
        }

        @Test("decodingFailed carries underlying error")
        func decodingFailed() {
            let underlying = DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "test")
            )
            let kind = NetworkError.Kind.decodingFailed(underlying)
            if case .decodingFailed = kind {
                // passes
            } else {
                Issue.record("Expected .decodingFailed")
            }
        }

        @Test("transportFailed carries underlying error")
        func transportFailed() {
            let underlying = URLError(.timedOut)
            let kind = NetworkError.Kind.transportFailed(underlying)
            if case .transportFailed = kind {
                // passes
            } else {
                Issue.record("Expected .transportFailed")
            }
        }

        @Test("encodingFailed carries underlying error")
        func encodingFailed() {
            let underlying = EncodingError.invalidValue(
                "", .init(codingPath: [], debugDescription: "test")
            )
            let kind = NetworkError.Kind.encodingFailed(underlying)
            if case .encodingFailed = kind {
                // passes
            } else {
                Issue.record("Expected .encodingFailed")
            }
        }
    }

    @Suite("Pattern Matching on Kind")
    struct KindPatternMatching {
        @Test("exact status code match on Kind")
        func exactMatch() {
            let kind = NetworkError.Kind.invalidStatus(404)
            switch kind {
            case .invalidStatus(404):
                break // passes
            default:
                Issue.record("Expected .invalidStatus(404) to match")
            }
        }

        @Test("range match on Kind for 5xx")
        func rangeMatch() {
            let kind = NetworkError.Kind.invalidStatus(503)
            switch kind {
            case .invalidStatus(500...):
                break // passes
            default:
                Issue.record("Expected .invalidStatus(503) to match 500...")
            }
        }
    }

    @Suite("Direct Pattern Matching on NetworkError")
    struct DirectPatternMatching {
        @Test("exact Int match on NetworkError")
        func exactIntMatch() {
            let error = NetworkErrorTests.httpError(statusCode: 404)
            switch error {
            case 404:
                break // passes
            default:
                Issue.record("Expected NetworkError to match 404")
            }
        }

        @Test("range match on NetworkError for 5xx")
        func rangeMatch() {
            let error = NetworkErrorTests.httpError(statusCode: 503)
            switch error {
            case 500...:
                break // passes
            default:
                Issue.record("Expected NetworkError to match 500...")
            }
        }

        @Test("non-invalidStatus kind does not match any status code")
        func nonStatusKindNoMatch() {
            let error = NetworkErrorTests.transportError(URLError(.timedOut))
            switch error {
            case 500:
                Issue.record("transportFailed should not match status codes")
            default:
                break // passes
            }
        }
    }

    @Suite("Convenience Properties with Response")
    struct ConvenienceWithResponse {
        let error = NetworkError(
            kind: .invalidStatus(404),
            request: .get("/test"),
            response: Response(
                statusCode: 404,
                headers: [.contentType: "application/json"],
                body: Data("not found".utf8)
            )
        )

        @Test("statusCode returns response status code")
        func statusCode() {
            #expect(error.statusCode == 404)
        }

        @Test("body returns response body")
        func body() {
            #expect(error.body == Data("not found".utf8))
        }

        @Test("headers returns response headers")
        func headers() {
            #expect(error.headers == [.contentType: "application/json"])
        }

        @Test("isClientError is true for 4xx")
        func isClientError() {
            #expect(error.isClientError == true)
        }

        @Test("isServerError is false for 4xx")
        func isServerError() {
            #expect(error.isServerError == false)
        }

        @Test("isServerError is true for 5xx")
        func serverError() {
            let serverError = NetworkError(
                kind: .invalidStatus(500),
                request: .get("/test"),
                response: Response(statusCode: 500, headers: [:], body: Data())
            )
            #expect(serverError.isServerError == true)
            #expect(serverError.isClientError == false)
        }
    }

    @Suite("Convenience Properties without Response")
    struct ConvenienceWithoutResponse {
        let error = NetworkError(
            kind: .transportFailed(URLError(.notConnectedToInternet)),
            request: .get("/test"),
            response: nil
        )

        @Test("statusCode is nil")
        func statusCode() {
            #expect(error.statusCode == nil)
        }

        @Test("body is nil")
        func body() {
            #expect(error.body == nil)
        }

        @Test("headers is nil")
        func headers() {
            #expect(error.headers == nil)
        }

        @Test("isClientError is false")
        func isClientError() {
            #expect(error.isClientError == false)
        }

        @Test("isServerError is false")
        func isServerError() {
            #expect(error.isServerError == false)
        }
    }

    @Suite("Factory Methods")
    struct FactoryMethods {
        @Test("http(statusCode:) creates invalidStatus error")
        func httpFactory() {
            let error = NetworkErrorTests.httpError(statusCode: 500)
            if case .invalidStatus(500) = error.kind {
                // passes
            } else {
                Issue.record("Expected .invalidStatus(500)")
            }
        }

        @Test("transportError creates transportFailed error")
        func transportFactory() {
            let underlying = URLError(.timedOut)
            let error = NetworkErrorTests.transportError(underlying)
            if case .transportFailed = error.kind {
                // passes
            } else {
                Issue.record("Expected .transportFailed")
            }
        }

        @Test("factory errors carry stub request")
        func factoryCarriesStubRequest() {
            let error = NetworkErrorTests.httpError(statusCode: 404)
            #expect(error.request.method == .get)
        }
    }

    @Suite("Error Conformance")
    struct ErrorConformance {
        @Test("NetworkError conforms to Error and can be thrown")
        func canBeThrown() {
            let error = NetworkErrorTests.httpError(statusCode: 500)
            #expect(throws: NetworkError.self) {
                throw error
            }
        }
    }
}
