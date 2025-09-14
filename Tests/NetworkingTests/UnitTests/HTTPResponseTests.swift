//
// HTTPResponseTest.swift
// UtilsTests
//
// Created by Dong on 9/12/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation
import Testing

@testable import Networking

@Suite("HTTPResponse Tests")
struct HTTPResponseTests {

    let testData = try! JSONEncoder()
        .encode(MockUser(id: 1, name: "John", email: "john@example.com"))
    let testURL = URL(string: "https://api.example.com/users")!

    func createHTTPResponse(statusCode: Int, data: Data = Data()) -> HTTPResponse {
        let httpResponse = HTTPURLResponse(
            url: testURL,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return HTTPResponse(data: data, httpResponse: httpResponse)
    }

    /// Test if successful response validation passes correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a successful HTTP response \
    /// When validating the response \
    /// Then the validation should pass successfully
    @Test("Successful response should pass validation correctly")
    func validateSuccessfulStatusCode() throws {
        let expectedStatusCode = 200
        let expectedData = testData

        try createHTTPResponse(statusCode: expectedStatusCode, data: expectedData).validate()
    }

    /// Test if failed status code throws NetworkingError correctly with appropriate code
    ///
    /// **Acceptance Criteria:** \
    /// Given a HTTP response with failed status code \
    /// When validating the response \
    /// Then NetworkingError.statusCode should be thrown
    @Test(
        "Validating response with failed status code should throw NetworkingError",
        arguments: [404, 500, 503])
    func validateFailedStatusCode(statusCode: Int) {
        #expect(throws: NetworkingError.statusCode(statusCode)) {
            try createHTTPResponse(statusCode: statusCode).validate()
        }
    }

    /// Test if custom status code range validation works correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given A HTTP response instance \
    /// And a custom valid status code range is provided \
    /// When validating the response \
    /// Then the custom range should be used for validation
    @Test(
        "Custom status code validation should work correctly",
        arguments: [200, 201], [200...200, 201...299])
    func validateCustomStatusCodeRange(
        statusCode: Int,
        validStatusCodes: ClosedRange<Int>
    ) throws {
        if validStatusCodes.contains(statusCode) {
            try validateResponse(with: statusCode, in: validStatusCodes)
        }
        else {
            #expect(throws: NetworkingError.statusCode(statusCode)) {
                try validateResponse(with: statusCode, in: validStatusCodes)
            }
        }

        // Helper to reduce code duplication
        func validateResponse(
            with statusCode: Int,
            in validStatusCodes: ClosedRange<Int>
        ) throws {
            try createHTTPResponse(statusCode: statusCode, data: testData)
                .validate(statusCodes: validStatusCodes)
        }
    }

    /// Test if custom validator is applied correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given a response and custom validator \
    /// When validating with custom validation logic \
    /// Then the custom validation should be applied
    @Test("Custom validator should be applied correctly")
    func validateWithCustomValidator() throws {
        let response = try createHTTPResponse(statusCode: 200, data: testData)
            .validate {
                guard $0.data.count > 0 else {
                    throw NetworkingError.noData
                }
            }

        #expect(response.data.count > 0)
    }

    /// Test if failing custom validator throws error correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given A response and failing custom validator \
    /// When Validating with custom validation that fails \
    /// Then The custom error should be thrown
    @Test("Failing custom validator should throw error correctly")
    func validateWithFailingCustomValidator() {
        #expect(throws: NetworkingError.noData) {
            try createHTTPResponse(statusCode: 200)
                .validate { response in
                    guard response.data.count > 0 else {
                        throw NetworkingError.noData
                    }
                }
        }
    }

    /// Test if valid JSON response is decoded successfully
    ///
    /// **Acceptance Criteria:** \
    /// Given a HTTP request with valid JSON response \
    /// When decoding the response \
    /// Then the object should be decoded successfully into model
    @Test("Valid JSON response should be decoded successfully")
    func decodeSuccessfulResponse() throws {
        let user = try createHTTPResponse(statusCode: 200, data: testData)
            .decode(into: MockUser.self)

        #expect(user.id == 1)
        #expect(user.name == "John")
        #expect(user.email == "john@example.com")
    }

    /// Test if invalid JSON response throws decoding error
    ///
    /// **Acceptance Criteria:** \
    /// Given a HTTP request with invalid JSON response \
    /// When Decoding the response \
    /// Then NetworkingError.decodingError should be thrown
    @Test("Decoding invalid JSON response should throw decoding error")
    func decodeInvalidResponse() {
        let invalidData = "invalid json".data(using: .utf8)!

        #expect(throws: NetworkingError.decodingError) {
            try createHTTPResponse(statusCode: 200, data: invalidData)
                .decode(into: MockUser.self)
        }
    }

    /// Test if custom decoder is used correctly when provided
    ///
    /// **Acceptance Criteria:** \
    /// Given a HTTP response with snake_case JSON \
    /// And a custom decoder with convertFromSnakeCase strategy \
    /// When decoding the response with custom decoder \
    /// Then the custom decoder should be used for decoding
    @Test("Custom decoder should be used correctly")
    func decodeWithCustomDecoder() throws {
        let customDecoder = JSONDecoder()
        customDecoder.keyDecodingStrategy = .convertFromSnakeCase

        let snakeCaseUser = [
            "id": "1",
            "user_name": "John",
            "email_address": "john@example.com",
        ]
        let snakeCaseData = try JSONSerialization.data(withJSONObject: snakeCaseUser)

        let user = try createHTTPResponse(statusCode: 200, data: snakeCaseData)
            .decode(into: TestSnakeCaseUser.self, using: customDecoder)

        #expect(user.id == "1")
        #expect(user.userName == "John")
        #expect(user.emailAddress == "john@example.com")

        // Custom model for snake_case decoding test
        struct TestSnakeCaseUser: Codable {
            let id: String
            let userName: String
            let emailAddress: String
        }
    }

    /// Test if raw data can be accessed correctly
    ///
    /// **Acceptance Criteria:** \
    /// Given A response with data \
    /// When Accessing raw data \
    /// Then The original data should be returned
    @Test("Raw data should be accessed correctly")
    func accessRawData() {
        let rawData = createHTTPResponse(statusCode: 200, data: testData).rawData

        #expect(rawData == testData)
    }
}
