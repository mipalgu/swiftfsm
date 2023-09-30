import KripkeStructure
import XCTest

func compare(_ lhs: KripkeStateProperty, _ rhs: KripkeStateProperty, key: String? = nil) {
    switch (lhs.type, rhs.type) {
    case (.Compound(let lplist), .Compound(let rplist)):
        compare(lplist, rplist, key: key)
    case (.Optional(let lopt), .Optional(let ropt)):
        XCTAssertEqual(
            lopt == nil,
            ropt == nil,
            "for key \(key ?? "<none>")"
        )
        guard let loptValue = lopt, let roptValue = ropt else {
            return
        }
        compare(loptValue, roptValue)
    case (.Collection(let larr), .Collection(let rarr)):
        XCTAssertEqual(larr.count, rarr.count, "for key \(key ?? "<none>")")
        guard larr.count == rarr.count else { return }
        for (larrValue, rarrValue) in zip(larr, rarr) {
            compare(larrValue, rarrValue)
        }
    default:
        XCTAssertEqual(lhs.type, rhs.type)
        if lhs.type != rhs.type {
            return
        }
        XCTAssertEqual(lhs, rhs, "for key \(key ?? "<none>")")
    }
}

func compare(_ lhs: KripkeStatePropertyList, _ rhs: KripkeStatePropertyList, key: String? = nil) {
    if lhs == rhs {
        XCTAssertEqual(lhs, rhs)
        return
    }
    let lsorted = lhs.properties.sorted { $0.key < $1.key }
    let rsorted = rhs.properties.sorted { $0.key < $1.key }
    for ((lkey, lvalue), (rkey, rvalue)) in zip(lsorted, rsorted) {
        XCTAssertEqual(lkey, rkey, "keys of property list do not match")
        if lkey != rkey { continue }
        compare(lvalue, rvalue, key: key.map { $0 + "." + lkey } ?? lkey)
    }
}
