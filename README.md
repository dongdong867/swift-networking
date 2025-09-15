# swift-networking

A lightweight, fluent, and powerful networking library for Swift, designed to make building and
sending HTTP requests simple and elegant.

## Features

- [x] **Fluent Interface:** Chain methods to build requests in a readable and intuitive way.
- [x] **Async/Await:** Built from the ground up for modern Swift concurrency.
- [x] **Robust Error Handling:** Comprehensive error enum to easily handle networking failures.
- [x] **Automatic Retries:** Configure automatic retries with customizable delays and conditions.
- [x] **Easy Decoding:** Decode JSON responses into your `Decodable` models with single method call.
- [x] **Status Code Validation:** Automatic and manual validation of HTTP status codes.
- [x] **Lightweight & Performant:** Built on top of `URLSession` with no external dependencies.

## Installation

You can add SwiftNetworking to your project using Swift Package Manager. In Xcode, go to `File > Add Packages...` and enter the repository URL:

```text
https://github.com/dongdong867/swift-networking.git
```

Then, add `"Networking"` to your target's dependencies.

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/dongdong867/swift-networking.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Networking"]
    )
]
```

## Usage

### Making a Simple GET Request

Define your endpoint and then create and send the request. The response can be easily decoded into a `Decodable` model.

```swift
let endpoint = HTTPNetworkEndpoint(string: "https://api.example.com/users/1")
let user = try await HTTPClient.get(endpoint)
    .send()
    .decode(into: YOUR_DECODABLE_MODEL.self)
```

### Building a POST Request with Headers and Body

The fluent interface makes it easy to configure headers, authentication, and the request body.

```swift
struct NewUser: Encodable {
    let name: String
    let email: String
}

let newUser = NewUser(name: "John Doe", email: "john.doe@example.com")
let apiToken = "your-secret-api-token"
let endpoint = HTTPNetworkEndpoint(string: "https://api.example.com/users")

let response = try await HTTPClient.post(endpoint)
    .bearer(token: apiToken) // Set bearer token
    .jsonBody(newUser)       // Encode and set the JSON body
    .send()
```

### Automatic Retries

Configure a request to automatically retry on failure. You can specify the number of retries,
the delay, and the conditions under which a retry should occur.

```swift
let endpoint = HTTPNetworkEndpoint(string: "https://api.example.com/users/1")
let response = try await HTTPClient.get(endpoint)
    // Retry 3 times with a 2-second delay between attempts
    .retry(3, delay: 2.0) { error, attempt in
        // Custom condition: only retry on server errors (5xx) or timeouts
        if case NetworkingError.statusCode(let code) = error { return code >= 500 }
        return error is URLError
    }
    .send()
```

### Error Handling

Handle specific networking errors by catching the `NetworkingError` enum.

```swift
let endpoint = HTTPNetworkEndpoint(string: "https://api.example.com/not-found")
do {
    try await HTTPClient.get(endpoint).send()
} catch let error as NetworkingError {
    switch error {
    case .invalidURL:
        print("The URL is invalid.")
    case .statusCode(let code):
        print("Received an unacceptable status code: \(code)")
    case .decodingError:
        print("Failed to decode the response.")
    case .noData:
        print("The response contained no data.")
    default:
        print("An unknown networking error occurred.")
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the Apache License, Version 2.0.
See the [LICENSE](LICENSE) file for details.
