//
// HTTPRequest.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

final class HTTPRequest {
    internal var url: URL
    internal var method: HTTPMethod
    internal var headers: [String: String] = [:]
    internal var queryParameters: [String: String] = [:]
    internal var body: Data?
    internal var timeoutInterval: TimeInterval = 30.0

    // Retry configuration
    internal var retryCount: Int = 1
    internal var retryDelay: TimeInterval = 1
    internal var shouldRetryBlock: ((Error, Int) -> Bool)? = nil

    init(url: URL, method: HTTPMethod) {
        self.url = url
        self.method = method
    }
}

// MARK: - Header
extension HTTPRequest {
    /// Set a single HTTP header field.
    ///
    /// - Parameters:
    ///   - key: Header field name.
    ///   - value: Header field value.
    /// - Returns: Self for method chaining.
    @discardableResult
    func header(_ key: String, _ value: String) -> HTTPRequest {
        self.headers[key] = value
        return self
    }

    /// Set multiple HTTP headers. Merges the provided headers with existing ones.
    ///
    /// - Parameter headers: Dictionary of header fields to set.
    /// - Returns: Self for method chaining.
    @discardableResult
    func headers(_ headers: [String: String]) -> HTTPRequest {
        self.headers.merge(headers) { _, new in new }
        return self
    }
}

// MARK: - Query Parameters
extension HTTPRequest {
    /// Add a single query parameter to the request URL.
    ///
    /// - Parameters:
    ///   - key: Query parameter name.
    ///   - value: Query parameter value.
    /// - Returns: Self for method chaining.
    @discardableResult
    func query(_ key: String, _ value: String) -> HTTPRequest {
        self.queryParameters[key] = value
        return self
    }

    /// Add multiple query parameters to the request URL.
    ///
    /// - Parameter parameters: Dictionary of query parameters to merge.
    /// - Returns: Self for method chaining.
    @discardableResult
    func queries(_ parameters: [String: String]) -> HTTPRequest {
        self.queryParameters.merge(parameters) { _, new in new }
        return self
    }
}

// MARK: - Body
extension HTTPRequest {
    /// Set the raw request body data.
    ///
    /// - Parameter data: Body bytes to send.
    /// - Returns: Self for method chaining.
    @discardableResult
    func body(_ data: Data) -> HTTPRequest {
        self.body = data
        return self
    }

    /// Sets JSON body and returns self for chaining
    ///
    /// - Parameters:
    ///   - object: Encodable object to encode as JSON.
    ///   - encoder: JSONEncoder instance to use (defaults to `JSONEncoder()`).
    /// - Returns: Self after setting the JSON body and `Content-Type` header.
    /// - Throws: Any encoding error thrown by the encoder.
    @discardableResult
    func jsonBody<T: Encodable>(
        _ object: T, encoder: JSONEncoder = JSONEncoder()
    ) throws -> HTTPRequest {
        self.body = try encoder.encode(object)
        self.headers["Content-Type"] = "application/json"
        return self
    }
}

// MARK: - Timeout & Retry
extension HTTPRequest {
    /// Set the request timeout interval.
    ///
    /// - Parameter interval: Timeout in seconds.
    /// - Returns: Self for method chaining.
    @discardableResult
    func timeout(_ interval: TimeInterval) -> HTTPRequest {
        self.timeoutInterval = interval
        return self
    }

    /// Configure retry behavior for the request.
    ///
    /// - Parameters:
    ///   - count: Number of retry attempts.
    ///   - delay: Delay between retries in seconds.
    ///   - if: Optional closure that determines whether to retry for a given error/attempt.
    /// - Returns: Self for method chaining.
    @discardableResult
    func retry(
        _ count: Int,
        delay: TimeInterval = 0,
        if condition: ((Error, Int) -> Bool)? = nil
    ) -> HTTPRequest {
        self.retryCount = max(0, count)
        self.retryDelay = max(0, delay)
        self.shouldRetryBlock = condition
        return self
    }
}

// MARK: - Response Handling
extension HTTPRequest {
    /// Executes the request with retry logic and returns HTTPResponse for chaining
    ///
    /// - Returns: An `HTTPResponse` object for method chaning.
    /// - Throws: Networking errors or URLSession errors encountered during the request.
    func send() async throws -> HTTPResponse {
        let (data, httpResponse) = try await executeWithRetry(operation: performSingleRequest)
        return HTTPResponse(data: data, httpResponse: httpResponse)
    }

    /// Performs a single network request without retry logic
    private func performSingleRequest() async throws -> (Data, HTTPURLResponse) {
        let request = try buildURLRequest()
        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = try validateHTTPResponse(response)
        return (data, httpResponse)
    }

    /// Validates the URLResponse is an HTTPURLResponse
    private func validateHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse
        else { throw NetworkingError.invalidResponse }

        return httpResponse
    }
}

// MARK: - URLRequest Building
extension HTTPRequest {
    /// Build and configure a `URLRequest` from the stored values.
    private func buildURLRequest() throws -> URLRequest {
        let urlComponents = try createURLComponents()
        let url = try buildURL(from: urlComponents)
        return configureURLRequest(with: url)
    }

    /// Create `URLComponents` from the base URL and query parameters.
    private func createURLComponents() throws -> URLComponents {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw NetworkingError.invalidURL
        }

        if !queryParameters.isEmpty {
            components.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }

        return components
    }

    /// Finalize `URL` from `URLComponents`.
    private func buildURL(from components: URLComponents) throws -> URL {
        guard let url = components.url
        else {
            throw NetworkingError.invalidURL
        }
        return url
    }

    /// Configure a `URLRequest` with method, headers, timeout, and body.
    private func configureURLRequest(with url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        request.httpBody = body

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Retry Handling
extension HTTPRequest {
    /// Execute an operation with the configured retry strategy.
    private func executeWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0...retryCount {
            do { return try await operation() }
            catch {
                lastError = error
                let shouldContinue = try await handleRetryLogic(error: error, attempt: attempt)
                if !shouldContinue { throw error }
            }
        }

        // This should never be reached due to the loop logic, but provides safety
        assertionFailure(lastError.debugDescription)
        throw lastError ?? NetworkingError.noData
    }

    /// Handles retry decision and delay
    private func handleRetryLogic(error: Error, attempt: Int) async throws -> Bool {
        guard
            attempt < retryCount,
            shouldRetryBlock?(error, attempt) ?? defaultShouldRetry(error: error)
        else { return false }

        if retryDelay > 0 { try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000)) }
        return true
    }

    /// Default retry logic for common scenarios.
    ///
    /// Retries when the error represents a server-side failure (HTTP 5xx) or
    /// transient networking problems such as timeouts or connection loss.
    /// Does not retry for client-side errors (HTTP 4xx).
    private func defaultShouldRetry(error: Error) -> Bool {
        if case NetworkingError.statusCode(let code) = error {
            return code >= 500
        }

        guard let urlError = error as? URLError
        else { return false }

        switch urlError.code {
        case .timedOut, .networkConnectionLost:
            return true
        default:
            return false
        }
    }
}
