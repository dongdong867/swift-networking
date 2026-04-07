# Server-Sent Events (SSE)

Lives in core Networking module (not separate). SSE is HTTP streaming with text parsing — thin enough to include, and `NetworkClient.stream()` needs to be accessible from macro-generated code.

## ServerSentEvent

```swift
struct ServerSentEvent: Sendable {
    var event: String?    // event type, nil means "message"
    var data: String      // payload (can be multi-line)
    var id: String?       // event ID for reconnection
    var retry: Int?       // reconnection delay in ms
}
```

Public type. Users who need raw event access use `ServerSentEvent` as the stream type.

## SSEParser

Consumes `URLSession.AsyncBytes`, parses per SSE spec, emits events:

```swift
struct SSEParser {
    static func events(from bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<ServerSentEvent, Error>
}
```

Parsing rules (per spec):
- Lines starting with `:` → comments, skip
- `field: value` → accumulate into current event
- `data:` can appear multiple times → join with `\n`
- Blank line → emit current event, reset
- Unknown fields → ignore

## Reconnection

Auto-reconnect on disconnect (on by default):

```swift
func stream<T: Decodable>(
    _ request: Request,
    as type: T.Type,
    event: String? = nil,
    reconnect: Bool = true
) -> AsyncThrowingStream<T, Error>
```

Reconnection loop:
1. Connect with `Last-Event-ID` header (if available)
2. Stream events, track `lastEventID` and `retryDelay`
3. On disconnect: if `reconnect` is true, wait `retryDelay` (default 3s), loop
4. Consumer sees continuous stream — reconnection is invisible
5. Cancel by cancelling the Task or breaking out of the for loop

## Event Filtering

`event:` parameter filters to specific event type:

```swift
// All events:
@SSE("/events")
var stream: @Sendable () -> AsyncThrowingStream<Message, Error>

// Filtered to "message" events only:
@SSE("/events", event: "message")
var messages: @Sendable () -> AsyncThrowingStream<Message, Error>

// With enum for type safety:
@SSE("/events", event: EventType.message)
var messages: @Sendable () -> AsyncThrowingStream<Message, Error>
```

`stream()` accepts both `String` and `RawRepresentable<String>` for the `event` parameter.

## SSEEventDecodable

For multi-event-type streams where different events have different payload types:

```swift
protocol SSEEventDecodable: Sendable {
    init?(event: String, data: Data) throws
}
```

When `T: SSEEventDecodable`, `stream()` uses `T.init(event:data:)` instead of plain JSON decoding. Events returning `nil` (unknown types) are skipped.

When `T: Decodable` (not SSEEventDecodable), all events are decoded as `T`.

When `T == ServerSentEvent`, raw events are returned without decoding.

## @SSEEvents Macro

Generates `SSEEventDecodable` conformance from an annotated enum:

```swift
@SSEEvents
enum FeedEvent {
    @Event("message") case message(Message)         // has payload
    @Event("user_joined") case userJoined(UserEvent) // has payload
    @Event("heartbeat") case heartbeat               // no payload
}
```

Generates:

```swift
extension FeedEvent: SSEEventDecodable {
    init?(event: String, data: Data) throws {
        let decoder = JSONDecoder()
        switch event {
        case "message":
            self = .message(try decoder.decode(Message.self, from: data))
        case "user_joined":
            self = .userJoined(try decoder.decode(UserEvent.self, from: data))
        case "heartbeat":
            self = .heartbeat
        default:
            return nil
        }
    }
}
```

Cases with associated values → decode. Cases without → construct directly.

## Full Usage

```swift
// Define events:
@SSEEvents
enum FeedEvent {
    @Event("message") case message(Message)
    @Event("user_joined") case userJoined(UserEvent)
    @Event("heartbeat") case heartbeat
}

// Define client:
@Client(base: "/feed")
struct FeedClient {
    @SSE("/events")
    @Authenticated
    var stream: @Sendable () -> AsyncThrowingStream<FeedEvent, Error>

    @SSE("/events", event: "message")
    @Authenticated
    var messages: @Sendable () -> AsyncThrowingStream<Message, Error>

    @SSE("/events/{channel}")
    @Authenticated
    var channelStream: @Sendable (_ channel: String) -> AsyncThrowingStream<FeedEvent, Error>
}

// Use:
for try await event in api.feed.stream() {
    switch event {
    case .message(let msg): showMessage(msg)
    case .userJoined(let user): showBanner(user)
    case .heartbeat: resetTimeout()
    }
}
```
