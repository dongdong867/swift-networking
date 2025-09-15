//
// HTTPClient.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// Represents an HTTP network endpoint (a full URL).
public struct HTTPNetworkEndpoint: Equatable, Hashable, Sendable {
    let url: URL

    /// Initialize with a `URL`
    ///
    /// - Parameter url: The concrete `URL` for the endpoint
    public init(url: URL) {
        self.url = url
    }

    /// Initialize with base URL and path
    ///
    /// This initializer combines a base URL and a path to form a complete URL string.
    ///
    /// - Parameters:
    ///   - baseURLString: The base URL string (e.g., "https://api.example.com")
    ///   - path: The relative endpoint path (e.g., "/v1/resource")
    /// - Throws: `NetworkingError.invalidURL` if the combined URL is not valid
    public init(baseURLString: String, path: String) throws {
        guard
            let base = URL(string: baseURLString),
            let scheme = base.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            base.host != nil
        else { throw NetworkingError.invalidURL }

        let cleanedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.url = cleanedPath.isEmpty ? base : base.appendingPathComponent(cleanedPath)
    }

    /// Initialize with a full URL string
    ///
    /// - Parameter string: The complete URL string (e.g., "https://api.example.com/v1/resource")
    /// - Throws: `NetworkingError.invalidURL` if the string is not a valid URL
    public init(string: String) throws {
        guard
            let url = URL(string: string),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else { throw NetworkingError.invalidURL }
        self.url = url
    }
}

/// A lightweight HTTP client factory that produces `HTTPRequest` instances
/// configured for common HTTP methods.
///
/// Marked `public` so callers outside the module can invoke high-level helpers
/// like `HTTPClient.get(...)` to obtain a configured `HTTPRequest`.
public enum HTTPClient {
    // MARK: - HTTP Methods

    /// Create a `HTTPRequest` configured for HTTP GET.
    ///
    /// - Parameter endpoint: The endpoint to target.
    /// - Returns: A configured `HTTPRequest`.
    public static func get(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .GET, endpoint: endpoint)
    }

    /// Create a `HTTPRequest` configured for HTTP POST.
    ///
    /// - Parameter endpoint: The endpoint to target.
    /// - Returns: A configured `HTTPRequest`.
    public static func post(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .POST, endpoint: endpoint)
    }

    /// Create a `HTTPRequest` configured for HTTP PUT.
    ///
    /// - Parameter endpoint: The endpoint to target.
    /// - Returns: A configured `HTTPRequest`.
    public static func put(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .PUT, endpoint: endpoint)
    }

    /// Create a `HTTPRequest` configured for HTTP DELETE.
    ///
    /// - Parameter endpoint: The endpoint to target.
    /// - Returns: A configured `HTTPRequest`.
    public static func delete(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .DELETE, endpoint: endpoint)
    }

    /// Create a `HTTPRequest` configured for HTTP PATCH.
    ///
    /// - Parameter endpoint: The endpoint to target.
    /// - Returns: A configured `HTTPRequest`.
    public static func patch(_ endpoint: HTTPNetworkEndpoint) throws -> HTTPRequest {
        try request(method: .PATCH, endpoint: endpoint)
    }

    // MARK: - Private Helper

    /// Internal helper to create a `HTTPRequest` for a given method/endpoint.
    private static func request(
        method: HTTPMethod, endpoint: HTTPNetworkEndpoint
    ) throws -> HTTPRequest {
        HTTPRequest(url: endpoint.url, method: method)
    }
}
