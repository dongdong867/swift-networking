//
// HTTPClientTests.swift
// UtilsTests
//
// Created by Dong on 9/12/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation
import Testing

@testable import Networking

@Suite("HTTPClient Factory")
struct HTTPClientTests {
    enum Mock {
        static let validBaseURL = "https://api.example.com"
        static let invalidBaseURL = "ht tp://invalid url with spaces"
        static let path = "/users"
        static var expectedURL: URL {
            guard let base = URL(string: validBaseURL) else {
                preconditionFailure("Invalid test base URL")
            }

            let cleanedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return base.appendingPathComponent(cleanedPath)
        }
    }

    // MARK: - GET Method Tests

    /// Test if valid endpoint creates request correctly from base URL and path
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with base URL and path \
    /// When creating a GET request \
    /// Then the request should be created with correct URL and method
    @Test(
        "Valid endpoint (baseURL+path) should create request correctly",
        arguments: [(Mock.validBaseURL, Mock.path)])
    func createRequestWithValidEndpoint(baseURLString: String, path: String) throws {
        let endpoint = try HTTPNetworkEndpoint(baseURLString: baseURLString, path: path)
        let request = try HTTPClient.get(endpoint)

        #expect(request.method == .GET)
        #expect(request.url == Mock.expectedURL)
    }

    /// Test if valid endpoint creates request correctly from url string
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with url string \
    /// When creating a GET request \
    /// Then the request should be created with correct URL and method
    @Test(
        "Valid endpoint (urlString) should create request correctly",
        arguments: [Mock.validBaseURL + Mock.path]
    )
    func createRequestWithValidEndpoint(urlString: String) throws {
        let endpoint = try HTTPNetworkEndpoint(string: urlString)
        let request = try HTTPClient.get(endpoint)

        #expect(request.method == .GET)
        #expect(request.url == Mock.expectedURL)
    }

    /// Test if invalid endpoint throws NetworkingError correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an invalid endpoint path \
    /// When creating a request \
    /// Then networkingError.invalidURL should be thrown
    @Test("Invalid endpoint should throw NetworkingError correctly")
    func createRequestWithInvalidEndpoint() {
        #expect(throws: NetworkingError.invalidURL) {
            try HTTPClient.get(.init(baseURLString: Mock.invalidBaseURL, path: Mock.path))
        }
    }

    // MARK: - PUT Method Tests

    /// Test if valid endpoint creates PUT request correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with base URL and path \
    /// When creating a PUT request \
    /// Then the request should be created with correct URL and PUT method
    @Test("Valid endpoint should create PUT request correctly")
    func createPUTRequestWithValidEndpoint() throws {
        let request = try HTTPClient.put(.init(baseURLString: Mock.validBaseURL, path: Mock.path))

        #expect(request.method == .PUT)
        #expect(request.url == Mock.expectedURL)
    }

    /// Test if invalid endpoint throws NetworkingError for PUT request
    ///
    /// **Acceptance Criteria:** \
    /// Given an invalid endpoint \
    /// When creating a PUT request \
    /// Then NetworkingError.invalidURL should be thrown
    @Test("Invalid endpoint should throw NetworkingError for PUT request")
    func createPUTRequestWithInvalidEndpoint() {
        #expect(throws: NetworkingError.invalidURL) {
            try HTTPClient.put(.init(baseURLString: Mock.invalidBaseURL, path: Mock.path))
        }
    }

    // MARK: - DELETE Method Tests

    /// Test if valid endpoint creates DELETE request correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with base URL and path \
    /// When creating a DELETE request \
    /// Then the request should be created with correct URL and DELETE method
    @Test("Valid endpoint should create DELETE request correctly")
    func createDELETERequestWithValidEndpoint() throws {
        let request = try HTTPClient.delete(
            .init(baseURLString: Mock.validBaseURL, path: Mock.path))

        #expect(request.method == .DELETE)
        #expect(request.url == Mock.expectedURL)
    }

    /// Test if invalid endpoint throws NetworkingError for DELETE request
    ///
    /// **Acceptance Criteria:** \
    /// Given an invalid endpoint \
    /// When creating a DELETE request \
    /// Then NetworkingError.invalidURL should be thrown
    @Test("Invalid endpoint should throw NetworkingError for DELETE request")
    func createDELETERequestWithInvalidEndpoint() {
        #expect(throws: NetworkingError.invalidURL) {
            try HTTPClient.delete(.init(baseURLString: Mock.invalidBaseURL, path: Mock.path))
        }
    }

    // MARK: - PATCH Method Tests

    /// Test if valid endpoint creates PATCH request correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with base URL and path \
    /// When creating a PATCH request \
    /// Then the request should be created with correct URL and PATCH method
    @Test("Valid endpoint should create PATCH request correctly")
    func createPATCHRequestWithValidEndpoint() throws {
        let request = try HTTPClient.patch(.init(baseURLString: Mock.validBaseURL, path: Mock.path))

        #expect(request.method == .PATCH)
        #expect(request.url == Mock.expectedURL)
    }

    /// Test if invalid endpoint throws NetworkingError for PATCH request
    ///
    /// **Acceptance Criteria:** \
    /// Given an invalid endpoint \
    /// When creating a PATCH request \
    /// Then NetworkingError.invalidURL should be thrown
    @Test("Invalid endpoint should throw NetworkingError for PATCH request")
    func createPATCHRequestWithInvalidEndpoint() {
        #expect(throws: NetworkingError.invalidURL) {
            try HTTPClient.patch(.init(baseURLString: Mock.invalidBaseURL, path: Mock.path))
        }
    }
}
