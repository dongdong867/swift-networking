//
// HTTPResponse.swift
// Utils
//
// Created by Dong on 09/10/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// Represents an HTTP response that supports fluent validation and decoding
public struct HTTPResponse: Sendable {
    public let data: Data
    public let httpResponse: HTTPURLResponse

    /// Initialize an `HTTPResponse` from raw `Data` and an `HTTPURLResponse`.
    ///
    /// - Parameters:
    ///   - data: Raw response data.
    ///   - httpResponse: The HTTPURLResponse object.
    public init(data: Data, httpResponse: HTTPURLResponse) {
        self.data = data
        self.httpResponse = httpResponse
    }
}

// MARK: - Response Processing
extension HTTPResponse {
    /// Validate that the response HTTP status code is within the provided range.
    ///
    /// - Parameter statusCodes: The allowable HTTP status code range (default: 200...299).
    /// - Returns: The same `HTTPResponse` instance to allow method chaining.
    /// - Throws: `NetworkingError.statusCode` if the response status code is outside the allowed range.
    @discardableResult
    public func validate(statusCodes: ClosedRange<Int> = 200...299) throws -> HTTPResponse {
        guard statusCodes ~= httpResponse.statusCode else {
            throw NetworkingError.statusCode(httpResponse.statusCode)
        }
        return self
    }

    /// Execute a custom validation closure against this response.
    ///
    /// - Parameter validator: A closure that receives the `HTTPResponse` and may throw an error.
    /// - Returns: The same `HTTPResponse` instance to allow method chaining.
    /// - Throws: Any error thrown by the provided `validator` closure.
    @discardableResult
    public func validate(_ validator: (HTTPResponse) throws -> Void) throws -> HTTPResponse {
        try validator(self)
        return self
    }

    /// Decode the response body into a decodable given type.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the response data into.
    ///   - decoder: The `JSONDecoder` to use (defaults to a new `JSONDecoder()`).
    /// - Returns: An instance of the decoded type.
    /// - Throws: `NetworkingError.decodingError` when decoding fails.
    public func decode<T: Decodable>(
        into type: T.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        }
        catch {
            // Preserve a simple error surface for consumers; log the underlying error for diagnostics.
            #if DEBUG
            print("HTTPResponse.decode failed: \(error)")
            #endif
            throw NetworkingError.decodingError
        }
    }

    /// The raw response data as received from the network.
    ///
    /// Use this when you need the unprocessed bytes instead of a decoded model.
    public var rawData: Data {
        data
    }
}
