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

    let testURL = URL(string: "https://api.example.com/users")!

    /// Test if a single header is added correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an HTTPRequest instance \
    /// When setting a single header \
    /// Then the header should be added to the request
    @Test("Single header should be added correctly")
    func setSingleHeader() {
        let expectedHeader = ["Authorization": "Bearer token123"]

        let request = HTTPRequest(url: testURL, method: .GET)
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

        let request = HTTPRequest(url: testURL, method: .POST)
            .headers(expectedHeaders)

        #expect(request.headers == expectedHeaders)
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

        let request = HTTPRequest(url: testURL, method: .GET)
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

        let request = HTTPRequest(url: testURL, method: .GET)
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

        let request = HTTPRequest(url: testURL, method: .POST)
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

        let request = try HTTPRequest(url: testURL, method: .POST)
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
    func setJSONBodyWithEncodingError() {
        struct InvalidObject: Encodable {
            func encode(to encoder: Encoder) throws {
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
            try HTTPRequest(url: testURL, method: .POST).jsonBody(invalidObject)
        }
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

        let request = HTTPRequest(url: testURL, method: .GET)
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

        let request = HTTPRequest(url: testURL, method: .GET)
            .retry(expectedRetryCount, delay: expectedRetryDelay)

        #expect(request.retryCount == 3)
        #expect(request.retryDelay == 2.0)
    }
}
