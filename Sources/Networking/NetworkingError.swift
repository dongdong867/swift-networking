//
// NetworkingError.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// Errors produced by the networking layer.
public enum NetworkingError: Error, Equatable, Sendable {
    case invalidURL
    case noData
    case invalidResponse
    case statusCode(Int)
    case encodingError
    case decodingError
}

extension NetworkingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL is invalid."
        case .noData: return "No data was returned from the server."
        case .invalidResponse: return "The server response was invalid."
        case .statusCode(let code): return "Request failed with status code \(code)."
        case .encodingError: return "Failed to encode the request body."
        case .decodingError: return "Failed to decode the response body."
        }
    }
}
