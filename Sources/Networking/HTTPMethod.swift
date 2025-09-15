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
    /// HTTP DELETE
    case DELETE
    /// HTTP GET
    case GET
    /// HTTP PATCH
    case PATCH
    /// HTTP POST
    case POST
    /// HTTP PUT
    case PUT
}
