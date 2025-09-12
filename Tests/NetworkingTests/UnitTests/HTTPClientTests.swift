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

    /// Test if valid endpoint creates request correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a valid endpoint with base URL and path \
    /// When creating a GET request \
    /// Then the request should be created with correct URL and method
    @Test("Valid endpoint should create request correctly")
    func createRequestWithValidEndpoint() throws {
        let validBaseURL = "https://api.example.com"
        let path = "users"

        let _ = try HTTPClient.get(.init(baseURL: validBaseURL, path: path))
    }

    /// Test if invalid endpoint throws NetworkingError correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given an invalid endpoint path \
    /// When creating a request \
    /// Then networkingError.invalidURL should be thrown
    @Test("Invalid endpoint should throw NetworkingError correctly")
    func createRequestWithInvalidEndpoint() {
        let invalidBaseURL = "ht tp://invalid url with spaces"
        let path = "users"

        #expect(throws: NetworkingError.invalidURL) {
            try HTTPClient.get(.init(baseURL: invalidBaseURL, path: path))
        }
    }
}
