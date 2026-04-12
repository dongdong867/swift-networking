@testable import Networking
import Testing

@Suite("ContentType")
struct ContentTypeTests {
    @Test(arguments: [
        (ContentType.applicationJSON, "application/json"),
        (.formURLEncoded, "application/x-www-form-urlencoded"),
        (.text, "text/plain"),
        (.octetStream, "application/octet-stream"),
    ])
    func standardContentTypes(_ contentType: ContentType, _ expected: String) {
        #expect(contentType.rawValue == expected)
    }

    @Suite("Custom Content Type")
    struct CustomContentType {
        @Test func customRawValue() {
            let contentType = ContentType(rawValue: "application/msgpack")
            #expect(contentType.rawValue == "application/msgpack")
        }
    }

    @Suite("Header Value")
    struct HeaderValue {
        @Test func setContentTypeHeader() {
            var request = Request.post("/upload")
            request[header: .contentType] = ContentType.applicationJSON.rawValue
            #expect(request[header: .contentType] == "application/json")
        }
    }
}
