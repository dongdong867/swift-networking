//
// HTTPMethod.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// Represents the HTTP methods supported by the networking layer.
///
/// Marked `public` so callers outside the module can construct requests
/// and reference HTTP methods when needed.
public enum HTTPMethod: String {
    /// HTTP GET
    case GET = "GET"
    /// HTTP POST
    case POST = "POST"
    /// HTTP PUT
    case PUT = "PUT"
    /// HTTP DELETE
    case DELETE = "DELETE"
    /// HTTP PATCH
    case PATCH = "PATCH"
}
