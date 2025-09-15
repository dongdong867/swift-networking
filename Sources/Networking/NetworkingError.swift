//
// NetworkingError.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// Errors produced by the networking layer.
/// Marked `public` so callers outside the module can inspect and react to errors.
public enum NetworkingError: Error, Equatable {
    case invalidURL
    case noData
    case invalidResponse
    case statusCode(Int)
    case encodingError
    case decodingError
}
