//
// HTTPNetworkingTests.swift
// UtilsTests
//
// Created by Dong on 9/10/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation
import Testing

@testable import Networking

@Suite("HTTP Networking Tests")
struct HTTPNetworkingTests {
    @Suite("HTTPClient, HTTPRequest Integration Scenarios")
    struct IntegrationTests {
        enum Mock {
            static let url = URL(string: "https://api.example.com/users")!
            static let user = MockUser(id: 1, name: "John Doe", email: "john@example.com")
            static let endpoint = HTTPNetworkEndpoint(
                baseURL: "https://api.example.com", path: "/users")
            static let userData = try! JSONEncoder().encode(user)
            static let clientErrorResponse = HTTPURLResponse(
                url: url,
                statusCode: 400,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"])!
            static let successResponse = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"])!
        }

        /// Test if complete request chain works together correctly
        ///
        /// **Acceptance Criteria:** \
        /// Given a user with a `HTTPClient` with given base URL and path \
        /// And the user customize the request with method chains \
        /// When the user build the request \
        /// Then all components should work together properly
        @Test("Complete request chain should work together correctly")
        func completeRequestChain() throws {
            let request = try HTTPClient.post(Mock.endpoint)
                .header("Authorization", "Bearer token123")
                .header("User-Agent", "iOS App")
                .query("version", "1.0")
                .jsonBody(Mock.user)
                .timeout(30.0)
                .retry(3, delay: 1.0) { _, attempt in
                    attempt < 2
                }

            let bodyData = try #require(request.body)
            let user = try JSONDecoder().decode(MockUser.self, from: bodyData)

            #expect(request.method == .POST)
            #expect(request.url == Mock.url)
            #expect(request.headers["Authorization"] == "Bearer token123")
            #expect(request.headers["User-Agent"] == "iOS App")
            #expect(request.queryParameters["version"] == "1.0")
            #expect(request.timeoutInterval == 30.0)
            #expect(request.retryCount == 3)
            #expect(request.retryDelay == 1.0)
            // Validate request body
            #expect(user.id == user.id)
            #expect(user.name == user.name)
            #expect(user.email == user.email)
        }

        /// Test if retry function works correctly in request chain
        ///
        /// **Acceptance Criteria:** \
        /// Given an HTTPRequest with retry configuration \
        /// When the retry condition is evaluated \
        /// Then the retry function should be properly stored and accessible
        @Test("Retry function should work correctly in request chain")
        func retryFunctionInRequestChain() throws {
            var shouldRetryCallCount = 0
            let error = NetworkingError.statusCode(500)
            let request = try HTTPClient.get(Mock.endpoint)
                .retry(3, delay: 0.5) { _, attempt in
                    shouldRetryCallCount += 1
                    return attempt < 2
                }

            #expect(request.retryCount == 3)
            #expect(request.retryDelay == 0.5)
            #expect(request.shouldRetryBlock != nil)
            #expect(request.shouldRetryBlock?(error, 0) == true)
            #expect(request.shouldRetryBlock?(error, 2) == false)
            #expect(shouldRetryCallCount == 2)
        }

        /// Test if response processing chain works correctly
        ///
        /// **Acceptance Criteria:** \
        /// Given a HTTP response \
        /// When processing the response through mutliple chained validations \
        /// Then all validations should work together properly
        @Test("Response processing chain should work correctly")
        func completeResponseProcessingChain() throws {
            let httpResponse = HTTPURLResponse(
                url: Mock.url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"])!

            let user = try HTTPResponse(data: Mock.userData, httpResponse: httpResponse)
                .validate(statusCodes: 200...299)
                .validate { response in
                    guard !response.data.isEmpty else {
                        throw NetworkingError.noData
                    }
                }
                .decode(into: MockUser.self)

            #expect(user.id == 1)
            #expect(user.name == "John Doe")
            #expect(user.email == "john@example.com")
        }

        /// Test if validation fails correctly in response processing chain
        ///
        /// **Acceptance Criteria:** \
        /// Given a HTTP response with failing validation conditions \
        /// When processing the response through validation chain \
        /// Then appropriate errors should be thrown at each validation step
        @Test("Validation should fail correctly in response processing chain")
        func validationFailureInResponseProcessingChain() throws {
            #expect(throws: NetworkingError.invalidResponse) {
                try HTTPResponse(data: Mock.userData, httpResponse: Mock.successResponse)
                    .validate(statusCodes: 200...299)  // This should pass
                    .validate { _ in
                        throw NetworkingError.invalidResponse  // This should fail
                    }
            }
        }
    }

    // MARK: - Error Handling Tests

    @Suite("Error Handling Scenarios")
    struct ErrorHandlingTests {
        let url = URL(string: "https://api.example.com/test")!

        /// Test if various HTTP status codes throw appropriate errors
        ///
        /// **Acceptance Criteria:** \
        /// Given various HTTP error status codes \
        /// When validating responses with these codes \
        /// Then appropriate NetworkingError.statusCode should be thrown
        @Test(
            "Various HTTP status codes should throw appropriate errors",
            arguments: [400, 401, 403, 404, 500, 502, 503])
        func handleVariousStatusCodes(statusCode: Int) {
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )!

            #expect(throws: NetworkingError.statusCode(statusCode)) {
                try HTTPResponse(data: Data(), httpResponse: httpResponse)
                    .validate()
            }
        }
    }
}
