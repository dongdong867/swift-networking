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
        let baseURL = "https://api.example.com"
        let path = "/users"
        let user = MockUser(id: 1, name: "John Doe", email: "john@example.com")

        /// Test if complete request chain works together correctly
        ///
        /// **Acceptance Criteria:** \
        /// Given a user with a `HTTPClient` with given base URL and path \
        /// And the user customize the request with method chains \
        /// When the user build the request \
        /// Then all components should work together properly
        @Test("Complete request chain should work together correctly")
        func completeRequestChain() throws {
            let request = try HTTPClient.post(.init(baseURL: baseURL, path: path))
                .header("Authorization", "Bearer token123")
                .header("User-Agent", "iOS App")
                .query("version", "1.0")
                .jsonBody(user)
                .timeout(30.0)
                .retry(3, delay: 1.0) { _, attempt in
                    attempt < 2
                }

            let bodyData = try #require(request.body)
            let user = try JSONDecoder().decode(MockUser.self, from: bodyData)

            #expect(request.method == .POST)
            #expect(request.url == URL(string: baseURL + path))
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

        /// Test if response processing chain works correctly
        ///
        /// **Acceptance Criteria:** \
        /// Given a HTTP response \
        /// When processing the response through mutliple chained validations \
        /// Then all validations should work together properly
        @Test("Response processing chain should work correctly")
        func completeResponseProcessingChain() throws {
            let testData = try JSONEncoder().encode(user)
            let httpResponse = #require(
                HTTPURLResponse(
                    url: URL(string: baseURL + path)!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                ))

            let user = try HTTPResponse(data: testData, httpResponse: httpResponse)
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
