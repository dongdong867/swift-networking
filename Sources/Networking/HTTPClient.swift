//
// HTTPClient.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

struct HTTPNetworkEndpoint {
    let urlString: String

    /// Initialize with base URL and path
    ///
    /// This initializer combines a base URL and a path to form a complete URL string.
    /// For more maintainable implementation, consider defining base URLs and paths
    /// as constants or enums.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL string (e.g., "https://api.example.com")
    ///   - path: The endpoint path (e.g., "/v1/resource")
    init(baseURL: String, path: String) {
        self.urlString = baseURL + path
    }

    /// Initialize with a full URL string
    ///
    /// - Parameter string: The complete URL string (e.g., "https://api.example.com/v1/resource")
    init(string: String) {
        self.urlString = string
    }
}

enum HTTPClient {
    // MARK: - HTTP Methods
    static func get(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .GET, endpoint: endpoint)
    }

    static func post(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .POST, endpoint: endpoint)
    }

    static func put(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .PUT, endpoint: endpoint)
    }

    static func delete(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .DELETE, endpoint: endpoint)
    }

    static func patch(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .PATCH, endpoint: endpoint)
    }

    // MARK: - Private Helper
    private static func request(
        method: HTTPMethod, endpoint: HTTPNetworkEndpoint
    ) throws -> HTTPRequest {
        guard let url = URL(string: endpoint.urlString) else {
            throw NetworkingError.invalidURL
        }

        return HTTPRequest(url: url, method: method)
    }
}
