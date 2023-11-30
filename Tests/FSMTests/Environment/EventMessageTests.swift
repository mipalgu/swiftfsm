import XCTest

@testable import FSM

final class EventMessageTests: XCTestCase {

    func test_init() {
        let eventCounter = UInt8(0)
        let value = UInt8(1)
        let message = EventMessage(eventCounter: eventCounter, value: value)
        XCTAssertEqual(message.eventCounter, eventCounter)
        XCTAssertEqual(message.value, value)
    }

    func test_initWithDefaultParameters() {
        let message = EventMessage<UInt8, UInt8>(value: UInt8(1))
        XCTAssertEqual(message.eventCounter, UInt8(0))
        XCTAssertEqual(message.value, UInt8(1))
    }

    func test_gettersAndSetters() {
        var message = EventMessage(eventCounter: UInt8(0), value: UInt8(0))
        XCTAssertEqual(message.eventCounter, UInt8(0))
        XCTAssertEqual(message.value, UInt8(0))
        message.eventCounter = UInt8(1)
        XCTAssertEqual(message.eventCounter, UInt8(1))
        XCTAssertEqual(message.value, UInt8(0))
        message.eventCounter = UInt8(0)
        XCTAssertEqual(message.eventCounter, UInt8(0))
        XCTAssertEqual(message.value, UInt8(0))
        message.value = UInt8(2)
        XCTAssertEqual(message.eventCounter, UInt8(0))
        XCTAssertEqual(message.value, UInt8(2))
    }

    func test_equality() {
        let message1 = EventMessage(eventCounter: UInt8(0), value: UInt8(0))
        let message2 = EventMessage(eventCounter: UInt8(0), value: UInt8(0))
        let message3 = EventMessage(eventCounter: UInt8(1), value: UInt8(0))
        let message4 = EventMessage(eventCounter: UInt8(0), value: UInt8(1))
        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
        XCTAssertNotEqual(message1, message4)
        XCTAssertNotEqual(message2, message3)
        XCTAssertNotEqual(message2, message4)
        XCTAssertNotEqual(message3, message4)
    }

    func test_hashing() {
        let message1 = EventMessage(eventCounter: UInt8(0), value: UInt8(0))
        let message2 = EventMessage(eventCounter: UInt8(0), value: UInt8(0))
        let message3 = EventMessage(eventCounter: UInt8(1), value: UInt8(0))
        let message4 = EventMessage(eventCounter: UInt8(0), value: UInt8(1))
        var collection = Set<EventMessage<UInt8, UInt8>>()
        collection.insert(message1)
        XCTAssertTrue(collection.contains(message1))
        XCTAssertTrue(collection.contains(message2))
        XCTAssertFalse(collection.contains(message3))
        XCTAssertFalse(collection.contains(message4))
    }

    func test_codable() throws {
        let message = EventMessage(eventCounter: UInt8(1), value: UInt8(2))
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try! encoder.encode(message)
        let decodedMessage = try decoder.decode(EventMessage<UInt8, UInt8>.self, from: data)
        XCTAssertEqual(message, decodedMessage)
    }

}
