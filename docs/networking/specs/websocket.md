# WebSocket

Lives in `NetworkingWebSocket` module. Separate because WebSocket is a different protocol with its own connection lifecycle, bidirectional communication, and uses `URLSessionWebSocketTask`.

## WebSocketMessage

```swift
enum WebSocketMessage: Sendable {
    case text(String)
    case data(Data)
}
```

## WebSocketCloseCode

```swift
enum WebSocketCloseCode: Sendable {
    case normalClosure
    case goingAway
    case protocolError
    case custom(Int)
}
```

## WebSocketConnection

Struct-with-closures for testability:

```swift
struct WebSocketConnection: Sendable {
    var messages: AsyncThrowingStream<WebSocketMessage, Error>
    var send: @Sendable (WebSocketMessage) async throws -> Void
    var close: @Sendable (WebSocketCloseCode) async -> Void
}
```

Testable:

```swift
let mock = WebSocketConnection(
    messages: AsyncThrowingStream { continuation in
        continuation.yield(.text("{\"text\": \"hello\"}"))
        continuation.finish()
    },
    send: { message in /* assert */ },
    close: { _ in }
)
```

## Typed Send/Receive

Convenience extensions for Codable messages:

```swift
extension WebSocketConnection {
    func send<T: Encodable>(_ value: T, encoder: any RequestEncoding = JSONEncoder()) async throws

    func messages<T: Decodable>(
        as type: T.Type,
        decoder: any ResponseDecoding = JSONDecoder()
    ) -> AsyncThrowingStream<T, Error>
}
```

## NetworkClient Integration

`NetworkClient.webSocket()` is defined as an extension in the NetworkingWebSocket module:

```swift
// In NetworkingWebSocket:
extension NetworkClient {
    func webSocket(_ request: Request) async throws -> WebSocketConnection
}
```

Users must `import NetworkingWebSocket` to use `@WebSocket` endpoints. If they forget, the compiler error is clear: `'NetworkClient' has no member 'webSocket'`.

## Macro Integration

```swift
@Client(base: "/chat")
struct ChatClient {
    @WebSocket("/room/{roomId}")
    @Authenticated
    var joinRoom: @Sendable (_ roomId: String) async throws -> WebSocketConnection
}
```

Macro generates:

```swift
joinRoom: { roomId in
    try await network.webSocket(
        Request.get("/chat/room/\(roomId)")
            .authenticated()
    )
}
```

## No Auto-Reconnect

Unlike SSE, WebSocket does NOT auto-reconnect:
- WebSocket is bidirectional — reconnecting doesn't restore conversation state
- The server may require re-authentication, room rejoining, etc.
- Application logic determines whether and how to reconnect

Consumer handles reconnection:

```swift
func connectToRoom(_ roomId: String) async {
    while !Task.isCancelled {
        do {
            let connection = try await api.chat.joinRoom(roomId)
            for try await message in connection.messages(as: ChatMessage.self) {
                showMessage(message)
            }
        } catch {
            try? await Task.sleep(for: .seconds(3))
        }
    }
}
```

## Middleware

Middleware applies to the initial HTTP upgrade request only (auth headers, logging the connection attempt). Once the WebSocket is established, messages bypass middleware.

## Full Usage

```swift
let connection = try await api.chat.joinRoom("general")

// Send typed:
try await connection.send(ChatMessage(type: "message", text: "hello"))

// Receive typed:
Task {
    for try await message in connection.messages(as: ChatMessage.self) {
        showMessage(message)
    }
}

// Close:
await connection.close(.normalClosure)
```
