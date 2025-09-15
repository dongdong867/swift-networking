//
// HTTPRequest.swift
// Utils
//
// Created by Dong on 9/8/25
// Copyright © 2025 dongdong867. All rights reserved.
//

import Foundation

/// A configurable HTTP request builder and executor.
///
/// `HTTPRequest` is designed to be created by `HTTPClient` helpers
/// (e.g. `HTTPClient.get(...)`) and then configured via a fluent API.
/// After configuration call `send()` to perform the request.
///
public final class HTTPRequest {
    internal var url: URL
    internal var method: HTTPMethod

    internal var headers: [String: String] = [:]
    internal var queryParameters: [String: String] = [:]
    internal var body: Data?
    internal var timeoutInterval: TimeInterval = 30.0
    internal var validStatusCodes: ClosedRange<Int> = 200...299

    // Retry configuration
    internal var retryCount: Int = 0
    internal var retryDelay: TimeInterval = 1
    internal var shouldRetryBlock: (@Sendable (Error, Int) -> Bool)?

    /// Construct an `HTTPRequest` with the specified URL and HTTP method.
    ///
    /// - Important: This initializer is `internal` to enforce usage via `HTTPClient` helpers.
    internal init(url: URL, method: HTTPMethod) {
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
    public func header(_ key: String, _ value: String) -> HTTPRequest {
        self.headers[key] = value
        return self
    }

    /// Set multiple HTTP headers. Merges the provided headers with existing ones.
    ///
    /// - Parameter headers: Dictionary of header fields to set.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func headers(_ headers: [String: String]) -> HTTPRequest {
        self.headers.merge(headers) { _, new in new }
        return self
    }

    /// Sets HTTP Basic Authentication header using the provided username and password.
    ///
    /// - Parameters:
    ///   - username: The username for basic auth.
    ///   - password: The password for basic auth.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func basic(username: String, password: String) -> HTTPRequest {
        let base64 = Data("\(username):\(password)".utf8).base64EncodedString()
        self.headers["Authorization"] = "Basic \(base64)"
        return self
    }

    /// Sets HTTP Bearer Authorization header using the provided token.
    ///
    /// - Parameter token: The bearer token.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func bearer(token: String) -> HTTPRequest {
        self.headers["Authorization"] = "Bearer \(token)"
        return self
    }

    /// Sets the User-Agent header to identify the client.
    ///
    /// - Parameter value: The User-Agent string.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func userAgent(_ value: String) -> HTTPRequest {
        guard !value.isEmpty else { return self }
        self.headers["User-Agent"] = value
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
    public func query(_ key: String, _ value: String) -> HTTPRequest {
        self.queryParameters[key] = value
        return self
    }

    /// Add multiple query parameters to the request URL.
    ///
    /// - Parameter parameters: Dictionary of query parameters to merge.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func queries(_ parameters: [String: String]) -> HTTPRequest {
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
    public func body(_ data: Data) -> HTTPRequest {
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
    public func jsonBody<T: Encodable>(
        _ object: T, encoder: JSONEncoder = JSONEncoder()
    ) throws -> HTTPRequest {
        self.body = try encoder.encode(object)
        self.headers["Content-Type"] = "application/json"
        return self
    }
}

// MARK: - Status Code Validation Configuration
extension HTTPRequest {
    /// Configure which HTTP status codes should be considered successful
    ///
    /// - Parameter statusCodes: Range of acceptable status codes
    /// - Returns: Self for method chaining
    @discardableResult
    public func acceptStatusCodes(_ statusCodes: ClosedRange<Int>) -> HTTPRequest {
        self.validStatusCodes = statusCodes
        return self
    }

    /// Disable automatic status code validation
    ///
    /// - Information: You can still manually setup validation logic in `HTTPResponse.validate(statusCodes:)`
    ///
    /// - Returns: Self for method chaining
    @discardableResult
    public func skipStatusValidation() -> HTTPRequest {
        self.validStatusCodes = 100...599  // Accept all standard HTTP status codes
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
    public func timeout(_ interval: TimeInterval) -> HTTPRequest {
        self.timeoutInterval = max(0, interval)
        return self
    }

    /// Configure retry behavior for the request.
    ///
    /// - Parameters:
    ///   - count: Number of retry attempts.
    ///   - delay: Delay between retries in seconds.
    ///   - condition: Optional closure that determines whether to retry for a given error/attempt.
    /// - Returns: Self for method chaining.
    @discardableResult
    public func retry(
        _ count: Int,
        delay: TimeInterval = 0,
        if condition: (@Sendable (Error, Int) -> Bool)? = nil
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
    /// - Returns: An `HTTPResponse` object for method chaining.
    /// - Throws: Networking errors or URLSession errors encountered during the request.
    /// Note: `HTTPResponse` is expected to be public in the module so callers can use the
    /// returned value for validation and decoding.
    public func send() async throws -> HTTPResponse {
        let (data, httpResponse) = try await executeWithRetry(operation: performSingleRequest)
        return HTTPResponse(data: data, httpResponse: httpResponse)
    }

    /// Performs a single network request without retry logic
    private func performSingleRequest() async throws -> (Data, HTTPURLResponse) {
        let request = try buildURLRequest()
        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = try validateHTTPResponse(response)
        try validateHTTPStatusCode(httpResponse)

        return (data, httpResponse)
    }

    /// Validates the URLResponse is an HTTPURLResponse
    internal func validateHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse
        else { throw NetworkingError.invalidResponse }

        return httpResponse
    }

    /// Validates HTTP status codes against configured acceptable range
    internal func validateHTTPStatusCode(_ httpResponse: HTTPURLResponse) throws {
        let statusCode = httpResponse.statusCode

        guard validStatusCodes.contains(statusCode) else {
            throw NetworkingError.statusCode(statusCode)
        }
    }
}

// MARK: - URLRequest Building
extension HTTPRequest {
    /// Build and configure a `URLRequest` from the stored values.
    internal func buildURLRequest() throws -> URLRequest {
        let urlComponents = try createURLComponents()
        let url = try buildURL(from: urlComponents)
        return configureURLRequest(with: url)
    }

    /// Create `URLComponents` from the base URL and query parameters.
    internal func createURLComponents() throws -> URLComponents {
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
    internal func buildURL(from components: URLComponents) throws -> URL {
        guard let url = components.url
        else {
            throw NetworkingError.invalidURL
        }
        return url
    }

    /// Configure a `URLRequest` with method, headers, timeout, and body.
    internal func configureURLRequest(with url: URL) -> URLRequest {
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
    internal func executeWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        let maxAttempts = retryCount + 1
        for attempt in 0..<maxAttempts {
            do { return try await operation() }
            catch {
                lastError = error

                let shouldContinue = try handleRetryLogic(error: error, attempt: attempt)
                guard shouldContinue else { throw error }

                try await Task.sleep(for: .seconds(retryDelay))
            }
        }

        // This should never be reached due to the loop logic, but provides safety
        assertionFailure(lastError.debugDescription)
        throw lastError ?? NetworkingError.noData
    }

    /// Handles retry decision and delay
    internal func handleRetryLogic(error: Error, attempt: Int) throws -> Bool {
        guard
            attempt < retryCount,
            shouldRetryBlock?(error, attempt) ?? defaultShouldRetry(error: error)
        else { return false }

        return true
    }

    /// Default retry logic for common scenarios.
    ///
    /// Retries when the error represents a server-side failure (HTTP 5xx) or
    /// transient networking problems such as timeouts or connection loss.
    /// Does not retry for client-side errors (HTTP 4xx).
    ///
    /// - Important: Function visibility is `internal` to allow testing.
    internal func defaultShouldRetry(error: Error) -> Bool {
        if case NetworkingError.statusCode(let code) = error {
            return code >= 500
        }

        guard let urlError = error as? URLError
        else { return false }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
