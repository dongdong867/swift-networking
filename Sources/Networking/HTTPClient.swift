//
// HTTPClient.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

struct HTTPNetworkEndpoint {
    var baseURL: String
    let path: String
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
        let baseURLString = endpoint.baseURL
        let pathString = endpoint.path

        guard let url = URL(string: baseURLString + pathString) else {
            throw NetworkingError.invalidURL
        }

        return HTTPRequest(url: url, method: method)
    }
}
