@testable import Networking
import Foundation
import Testing

@Suite("RequestEncoding")
struct RequestEncodingTests {
    @Suite("Acceptance")
    struct Acceptance {
        @Test func jsonEncodesValueToData() throws {
            let encoding = RequestEncoding.json
            let value = Greeting(message: "hello")
            let data = try encoding.encode(value)
            let decoded = try JSONDecoder().decode(Greeting.self, from: data)
            #expect(decoded == value)
        }

        @Test func jsonContentTypeIsApplicationJSON() {
            let encoding = RequestEncoding.json
            #expect(encoding.contentType == .applicationJSON)
        }

        @Test func encodingFailureThrows() {
            let encoding = RequestEncoding.json
            #expect(throws: EncodingError.self) {
                try encoding.encode(NonEncodable())
            }
        }

        @Test func customEncoderUsesConfiguration() throws {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoding = RequestEncoding.json(encoder)

            let date = Date(timeIntervalSince1970: 0)
            let data = try encoding.encode(Dated(date: date))
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            #expect(json["date"] as? String == "1970-01-01T00:00:00Z")
        }

        @Test func customEncodingUsesClosureAndContentType() throws {
            let customType = ContentType(rawValue: "application/msgpack")
            var closureCalled = false
            let encoding = RequestEncoding(contentType: customType) { _ in
                closureCalled = true
                return Data([0x01, 0x02])
            }

            let data = try encoding.encode(Greeting(message: "hi"))
            #expect(closureCalled)
            #expect(data == Data([0x01, 0x02]))
            #expect(encoding.contentType == customType)
        }
    }
}

// MARK: - Test Helpers

private struct Greeting: Codable, Equatable {
    let message: String
}

private struct Dated: Encodable {
    let date: Date
}

private struct NonEncodable: Encodable {
    func encode(to encoder: any Encoder) throws {
        throw EncodingError.invalidValue(
            self,
            EncodingError.Context(
                codingPath: [],
                debugDescription: "always fails"
            )
        )
    }
}
