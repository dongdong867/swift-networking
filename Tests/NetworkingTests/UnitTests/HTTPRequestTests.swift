//
// HTTPRequestTest.swift
// UtilsTests
//
// Created by Dong on 9/12/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation
import Testing

@testable import Networking

@Suite("HTTPRequest Tests")
struct HTTPRequestBuilderTests {
    /// Test if a single header is added correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting a single header \
    /// Then the header should be added to the request
    @Test("Single header should be added correctly")
    func setSingleHeader() {
        let expectedHeader = ["Authorization": "Bearer token123"]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .header("Authorization", "Bearer token123")

        #expect(request.headers == expectedHeader)
    }

    /// Test if multiple headers are merged correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and multiple headers \
    /// When setting multiple headers at once \
    /// Then all headers should be merged into the request
    @Test("Testing if multiple headers are merged correctly")
    func setMultipleHeaders() {
        let expectedHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer token123",
            "User-Agent": "iOS App",
        ]

        let request = HTTPRequest(url: .dummyURL, method: .POST)
            .headers(expectedHeaders)

        #expect(request.headers == expectedHeaders)
    }

    /// Test if basic authentication header is set correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting basic credentials \
    /// Then the `Authorization` header should be set to `Basic <base64>` correctly
    @Test("Basic auth header should be set correctly")
    func setBasicAuthorizationHeader() {
        let username = "user"
        let password = "pass"
        let credential = "\(username):\(password)"
        let encoded = Data(credential.utf8).base64EncodedString()
        let expectedHeader = ["Authorization": "Basic \(encoded)"]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .basic(username: username, password: password)

        #expect(request.headers == expectedHeader)
    }

    /// Test if the bearer authentication header is set correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting a bearer token \
    /// Then the `Authorization` header should be set to `Bearer <token>` correctly
    @Test("Bearer auth header should be set correctly")
    func setBearerAuthorizationHeader() {
        let token = "mytoken"
        let expectedHeader = ["Authorization": "Bearer \(token)"]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .bearer(token: token)

        #expect(request.headers == expectedHeader)
    }

    /// Test if the User-Agent header is set correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting a User-Agent value \
    /// Then the `User-Agent` header should be set correctly
    @Test("User-Agent header should be set correctly")
    func setUserAgentHeader() {
        let ua = "MyAgent/1.0"
        let expectedHeader = ["User-Agent": ua]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .userAgent(ua)

        #expect(request.headers == expectedHeader)
    }

    /// Test if a single query parameter is added correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When adding a single query parameter \
    /// Then the parameter should be added to the request
    @Test("Testing if a single query parameter is added correctly")
    func addSingleQueryParameter() {
        let expectedQuery = ["page": "1"]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .query("page", "1")

        #expect(request.queryParameters == expectedQuery)
    }

    /// Test if multiple query parameters are merged correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and multiple query parameters \
    /// When adding multiple queries at once \
    /// Then all parameters should be merged into the request
    @Test("Multiple query parameters should be merged correctly")
    func addMultipleQueryParameters() {
        let expectedQuery = ["page": "1", "limit": "20", "sort": "name"]

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .queries(expectedQuery)

        #expect(request.queryParameters == expectedQuery)
    }

    /// Test if valid raw body data can be set to body correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and raw data \
    /// When setting the body with raw data \
    /// And the body data is valid \
    /// Then the body should be set in the request
    @Test("Raw data should be set to body correctly")
    func setRawBodyData() {
        let expectedRawBodyData = "test data".data(using: .utf8)!

        let request = HTTPRequest(url: .dummyURL, method: .POST)
            .body(expectedRawBodyData)

        #expect(request.body == expectedRawBodyData)
    }

    /// Test if valid JSON body can be set to body correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and encodable object \
    /// When setting JSON body to request \
    /// And the object encoding is valid \
    /// Then the object should be encoded and content-type set
    @Test("Valid JSON should be set to body correctly")
    func setJSONBody() throws {
        let expectedUser = MockUser(id: 1, name: "John Doe", email: "john@example.com")

        let request = try HTTPRequest(url: .dummyURL, method: .POST)
            .jsonBody(expectedUser)

        let body = try #require(request.body)
        let user = try JSONDecoder().decode(MockUser.self, from: body)

        #expect(user == expectedUser)
        #expect(request.headers["Content-Type"] == "application/json")
    }

    /// Test if encoding error is thrown when setting invalid JSON to body
    ///
    /// **Acceptance Criteria:** \
    /// Given HTTPRequest instance and invalid encodable object \
    /// When setting JSON body to request \
    /// And the data will failed when encoding to JSON \
    /// Then an encoding error should be thrown
    @Test("Encoding error should be thrown for invalid JSON body")
    func setJSONBodyWithInvalidObject() {
        struct InvalidObject: Encodable {
            func encode(to _: Encoder) throws {
                throw EncodingError.invalidValue(
                    self,
                    EncodingError.Context(
                        codingPath: [],
                        debugDescription: "This object cannot be encoded"
                    )
                )
            }
        }

        let invalidObject = InvalidObject()

        #expect(throws: EncodingError.self) {
            try HTTPRequest(url: .dummyURL, method: .POST).jsonBody(invalidObject)
        }
    }

    /// Test if acceptable status code range is configured correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and status code range \
    /// When setting acceptable status codes \
    /// Then the status code range should be configured in the request
    @Test("Acceptable status code range should be configured correctly")
    func setAcceptableStatusCodes() {
        let expectedRange = 200...200

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .acceptStatusCodes(expectedRange)

        #expect(request.validStatusCodes == expectedRange)
    }

    /// Test if timeout interval is configured correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and timeout interval \
    /// When setting the timeout \
    /// Then the timeout should be configured in the request
    @Test("Timeout interval should be configured correctly")
    func setTimeout() {
        let expectedTimeout: TimeInterval = 60.0

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .timeout(expectedTimeout)

        #expect(request.timeoutInterval == expectedTimeout)
    }

    /// Test if retry configuration is set correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance and retry configuration \
    /// When setting retry options \
    /// Then the retry configuration should be applied to the request
    @Test("Retry configuration should be set correctly")
    func setRetryConfiguration() {
        let expectedRetryCount = 3
        let expectedRetryDelay: TimeInterval = 2.0

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .retry(expectedRetryCount, delay: expectedRetryDelay)

        #expect(request.retryCount == 3)
        #expect(request.retryDelay == 2.0)
        #expect(request.shouldRetryBlock == nil)
    }

    /// Test if retry count and delay timeinterval cannot be negative
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting negative retry count and delay timeinterval to the request \
    /// Then the retry count and delay timeinterval should be clamped to zero
    @Test(
        "Retry count and delay should be clamped to zero if negative",
        arguments: [-5], [-2.0])
    func retryCountAndDelayShouldFallbackWhenInvalid(count: Int, delay: TimeInterval) {
        let url = URL(string: "https://api.example.com")!
        let request = HTTPRequest(url: url, method: .GET)
            .retry(count, delay: delay)

        #expect(request.retryCount == 0)
        #expect(request.retryDelay == 0)
    }
}

@Suite("HTTPRequest Retry Logic Tests")
struct HTTPRequestRetryTests {
    /// Test if custom retry condition overrides default logic
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// And set a custom retry condition that disable retrying \
    /// When the retry handler received a error \
    /// Then the custom condition should take precedence over default logic
    @Test("Custom retry condition should override default logic")
    func customRetryConditionOverridesDefault() {
        var conditionCallCount = 0

        let request = HTTPRequest(url: .dummyURL, method: .GET)
            .retry(3, delay: 0) { _, _ in
                conditionCallCount += 1
                // Force return false for testing
                return false
            }

        let serverError = NetworkingError.statusCode(500)
        let shouldRetry =
            request.shouldRetryBlock?(serverError, 0)
            ?? request.defaultShouldRetry(error: serverError)

        #expect(conditionCallCount == 1)
        #expect(shouldRetry == false)
    }

    /// Test if server error HTTP status codes are retryable by default
    ///
    /// **Acceptance Criteria:** \
    /// Given various HTTP status codes that represent server errors \
    /// When evaluating default retry logic with the status codes \
    /// Then the retry logic should indicate these errors are retryable
    @Test(
        "Default retry logic should work correctly for HTTP status codes",
        arguments: [500, 501, 502, 503, 504, 505])
    func defaultShouldRetryForServerErrorCode(statusCode: Int) {
        let request = HTTPRequest(url: .dummyURL, method: .GET)

        let error = NetworkingError.statusCode(statusCode)
        #expect(
            request.defaultShouldRetry(error: error) == true,
            "Should retry for status code \(statusCode)")
    }

    /// Test if client error and success HTTP status codes are not retryable by default
    ///
    /// **Acceptance Criteria:** \
    /// Given various HTTP status codes that represent success and client errors \
    /// When evaluating default retry logic with the status codes \
    /// Then the retry logic should indicate these errors are not retryable
    @Test(
        "Default retry logic should work correctly for HTTP status codes",
        arguments: [200, 201, 202, 204, 400, 401, 403, 404, 409, 422])
    func defaultShouldNotRetryForSuccessAndClientErrorCode(statusCode: Int) {
        let request = HTTPRequest(url: .dummyURL, method: .GET)
        let error = NetworkingError.statusCode(statusCode)

        #expect(
            request.defaultShouldRetry(error: error) == false,
            "Should not retry for status code \(statusCode)")
    }
}

@Suite("Retry with real-world HTTP request tests")
struct RealworldRetryTests {
    /// Test if server errors trigger retry by default
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// And setup a retry handler to count retries \
    /// When the request fails with error \
    /// Then the request should retry according to default logic \
    /// And the retry counter should match expected retries
    @Test(
        "Retry should be triggered for server errors and escape for client errors",
        arguments: zip([URL.serverErrorURL, .clientErrorURL], [2, 0]))
    func retryHandlerShouldBehaveAsExpected(url: URL, expectedRetryCount: Int) async throws {
        let request = HTTPRequest(url: url, method: .GET)
        var counter = 0

        await #expect(throws: NetworkingError.self) {
            try await request.retry(2, delay: 0.2) { error, _ in
                let shouldRetry = request.defaultShouldRetry(error: error)
                if shouldRetry { counter += 1 }
                return shouldRetry
            }
            .send()
        }

        #expect(counter == expectedRetryCount)
    }

    /// Test if skipping status validation allows error status codes
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// And status validation is skipped \
    /// When received response with error status code \
    /// Then the request should succeed even with error status codes
    /// And validation can be applied manually after receiving response
    @Test("Skip validation allows error status codes")
    func validationCanBeSkipAndAddManually() async throws {
        let response = try await HTTPRequest(url: .serverErrorURL, method: .GET)
            .skipStatusValidation()
            .send()

        #expect(response.httpResponse.statusCode == 500)

        // Validate status code after received response
        #expect(throws: NetworkingError.statusCode(500)) {
            try response.validate()
        }
    }
}

extension URL {
    fileprivate static let dummyURL = URL(string: "https://api.example.com")!
    fileprivate static let clientErrorURL = URL(string: "https://httpbin.org/status/404")!
    fileprivate static let serverErrorURL = URL(string: "https://httpbin.org/status/500")!
}
