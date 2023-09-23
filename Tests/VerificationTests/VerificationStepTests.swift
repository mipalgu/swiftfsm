import KripkeStructure
import XCTest

@testable import Verification

final class VerificationStepTests: XCTestCase {

    let timeslot0 = Timeslot(
        executables: [0, 1, 2],
        callChain: CallChain(root: 0, calls: []),
        startingTime: 30,
        duration: 15,
        cyclesExecuted: 0
    )

    let timeslot1 = Timeslot(
        executables: [3, 4, 5],
        callChain: CallChain(root: 3, calls: []),
        startingTime: 60,
        duration: 20,
        cyclesExecuted: 0
    )

    let timeslot2 = Timeslot(
        executables: [6],
        callChain: CallChain(root: 6, calls: []),
        startingTime: 100,
        duration: 50,
        cyclesExecuted: 0
    )

    let timeslots: Set<Timeslot> = [
        Timeslot(
            executables: [0, 1, 2],
            callChain: CallChain(root: 0, calls: []),
            startingTime: 30,
            duration: 15,
            cyclesExecuted: 0
        ),
        Timeslot(
            executables: [3, 4, 5],
            callChain: CallChain(root: 3, calls: []),
            startingTime: 60,
            duration: 20,
            cyclesExecuted: 0
        ),
        Timeslot(
            executables: [6],
            callChain: CallChain(root: 6, calls: []),
            startingTime: 100,
            duration: 50,
            cyclesExecuted: 0
        )
    ]

    var allCases: [VerificationStep] {
        [
            .startDelegates(timeslots: timeslots),
            .endDelegates(timeslots: timeslots),
            .takeSnapshot(timeslots: timeslots),
            .takeSnapshotAndStartTimeslot(timeslot: timeslot0),
            .startTimeslot(timeslot: timeslot0),
            .execute(timeslot: timeslot0),
            .executeAndSaveSnapshot(timeslot: timeslot0),
            .saveSnapshot(timeslots: timeslots)
        ]
    }

    func testEquality() {
        let allCases = self.allCases
        for i in 0..<allCases.count {
            XCTAssertEqual(allCases[i], allCases[i])
            for j in 0..<allCases.count where j != i {
                XCTAssertNotEqual(allCases[i], allCases[j])
                XCTAssertNotEqual(allCases[j], allCases[i])
            }
        }
    }

    func testHashable() {
        let allCases = self.allCases
        var collection: Set<VerificationStep> = []
        for i in 0..<allCases.count {
            for j in 0..<allCases.count where j != i {
                collection.insert(allCases[j])
                XCTAssertFalse(collection.contains(allCases[i]))
            }
            collection.insert(allCases[i])
            XCTAssertTrue(collection.contains(allCases[i]))
            collection.removeAll(keepingCapacity: true)
        }
    }

    func testTakeSnapshot() {
        XCTAssertTrue(VerificationStep.takeSnapshot(timeslots: timeslots).takeSnapshot)
        XCTAssertTrue(VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).takeSnapshot)
        XCTAssertFalse(VerificationStep.startDelegates(timeslots: timeslots).takeSnapshot)
        XCTAssertFalse(VerificationStep.endDelegates(timeslots: timeslots).takeSnapshot)
        XCTAssertFalse(VerificationStep.startTimeslot(timeslot: timeslot0).takeSnapshot)
        XCTAssertFalse(VerificationStep.execute(timeslot: timeslot0).takeSnapshot)
        XCTAssertFalse(VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).takeSnapshot)
        XCTAssertFalse(VerificationStep.saveSnapshot(timeslots: timeslots).takeSnapshot)
    }

    func testSaveSnapshot() {
        XCTAssertTrue(VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).saveSnapshot)
        XCTAssertTrue(VerificationStep.saveSnapshot(timeslots: timeslots).saveSnapshot)
        XCTAssertFalse(VerificationStep.startDelegates(timeslots: timeslots).saveSnapshot)
        XCTAssertFalse(VerificationStep.endDelegates(timeslots: timeslots).saveSnapshot)
        XCTAssertFalse(VerificationStep.takeSnapshot(timeslots: timeslots).saveSnapshot)
        XCTAssertFalse(VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).saveSnapshot)
        XCTAssertFalse(VerificationStep.startTimeslot(timeslot: timeslot0).saveSnapshot)
        XCTAssertFalse(VerificationStep.execute(timeslot: timeslot0).saveSnapshot)
    }

    func testStartTimeslot() {
        XCTAssertTrue(VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).startTimeslot)
        XCTAssertTrue(VerificationStep.startTimeslot(timeslot: timeslot0).startTimeslot)
        XCTAssertFalse(VerificationStep.startDelegates(timeslots: timeslots).startTimeslot)
        XCTAssertFalse(VerificationStep.endDelegates(timeslots: timeslots).startTimeslot)
        XCTAssertFalse(VerificationStep.takeSnapshot(timeslots: timeslots).startTimeslot)
        XCTAssertFalse(VerificationStep.execute(timeslot: timeslot0).startTimeslot)
        XCTAssertFalse(VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).startTimeslot)
        XCTAssertFalse(VerificationStep.saveSnapshot(timeslots: timeslots).startTimeslot)
    }

    func testMarker() {
        XCTAssertEqual(VerificationStep.startDelegates(timeslots: timeslots).marker, "S")
        XCTAssertEqual(VerificationStep.endDelegates(timeslots: timeslots).marker, "E")
        XCTAssertEqual(VerificationStep.takeSnapshot(timeslots: timeslots).marker, "R")
        XCTAssertEqual(VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).marker, "R")
        XCTAssertEqual(VerificationStep.startTimeslot(timeslot: timeslot0).marker, "S")
        XCTAssertEqual(VerificationStep.execute(timeslot: timeslot0).marker, "E")
        XCTAssertEqual(VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).marker, "W")
        XCTAssertEqual(VerificationStep.saveSnapshot(timeslots: timeslots).marker, "W")
    }

    func testTimeslots() {
        XCTAssertEqual(VerificationStep.startDelegates(timeslots: timeslots).timeslots, timeslots)
        XCTAssertEqual(VerificationStep.endDelegates(timeslots: timeslots).timeslots, timeslots)
        XCTAssertEqual(VerificationStep.takeSnapshot(timeslots: timeslots).timeslots, timeslots)
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).timeslots,
            [timeslot0]
        )
        XCTAssertEqual(VerificationStep.startTimeslot(timeslot: timeslot0).timeslots, [timeslot0])
        XCTAssertEqual(VerificationStep.execute(timeslot: timeslot0).timeslots, [timeslot0])
        XCTAssertEqual(VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).timeslots, [timeslot0])
        XCTAssertEqual(VerificationStep.saveSnapshot(timeslots: timeslots).timeslots, timeslots)
    }

    func testExecutables() {
        let allExecutables: Set<Int> = [0, 3, 6]
        let singleExecutables: Set<Int> = [0]
        XCTAssertEqual(VerificationStep.startDelegates(timeslots: timeslots).executables, allExecutables)
        XCTAssertEqual(VerificationStep.endDelegates(timeslots: timeslots).executables, allExecutables)
        XCTAssertEqual(VerificationStep.takeSnapshot(timeslots: timeslots).executables, allExecutables)
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).executables,
            singleExecutables
        )
        XCTAssertEqual(VerificationStep.startTimeslot(timeslot: timeslot0).executables, singleExecutables)
        XCTAssertEqual(VerificationStep.execute(timeslot: timeslot0).executables, singleExecutables)
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).executables,
            singleExecutables
        )
        XCTAssertEqual(VerificationStep.saveSnapshot(timeslots: timeslots).executables, allExecutables)
    }

    // swiftlint:disable:next function_body_length
    func testPropertyWithSingleTimeslotWhenCollapseIfPossibleIsTrue() {
        func property(_ str: String) -> KripkeStateProperty {
            KripkeStateProperty(type: .String, value: str)
        }
        let state = "Ping"
        let timeslots: Set<Timeslot> = [timeslot0]
        // swiftlint:disable line_length
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("0.Ping.S")
        )
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("0.S")
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("0.Ping.E")
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("0.E")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("0.Ping.R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("0.R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            property("0.Ping.R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            property("0.R")
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            property("0.Ping.S")
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            property("0.S")
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            property("0.Ping.E")
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            property("0.E")
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            property("0.Ping.W")
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            property("0.W")
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("0.Ping.W")
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("0.W")
        )
        // swiftlint:enable line_length
    }

    // swiftlint:disable:next function_body_length
    func testPropertyWithSingleTimeslotWhenCollapseIfPossibleIsFalse() {
        func property(_ marker: String, _ state: String? = nil) -> KripkeStateProperty {
            let value: [String: Any] = [
                "step": marker,
                "fsms": ["0"],
                "state": state as Any
            ]
            let plist: [String: KripkeStateProperty] = [
                "step": KripkeStateProperty(type: .String, value: marker),
                "fsms": KripkeStateProperty(
                    type: .Collection([KripkeStateProperty(type: .String, value: "0")]),
                    value: ["0"]
                ),
                "state": KripkeStateProperty(
                    type: .Optional(state.map { KripkeStateProperty(type: .String, value: $0) }),
                    value: state as Any
                )
            ]
            return KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(properties: plist)),
                value: value
            )
        }
        let state = "Ping"
        let timeslots: Set<Timeslot> = [timeslot0]
        // swiftlint:disable line_length
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("S", state)
        )
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("S")
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("E", state)
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("E")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("R", state)
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("R", state)
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("R")
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("S", state)
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("S")
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("E", state)
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("E")
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("W", state)
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("W")
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("W", state)
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("W")
        )
        // swiftlint:enable line_length
    }

    // swiftlint:disable:next function_body_length
    func testPropertyWithMultipleTimeslotsWhenCollapseIfPossibleIsFalse() {
        // swiftlint:disable line_length
        func property(_ marker: String, _ state: String? = nil, _ fsms: [String] = ["0", "3", "6"]) -> KripkeStateProperty {
            let value: [String: Any] = [
                "step": marker,
                "fsms": fsms,
                "state": state as Any
            ]
            let plist: [String: KripkeStateProperty] = [
                "step": KripkeStateProperty(type: .String, value: marker),
                "fsms": KripkeStateProperty(
                    type: .Collection(fsms.map { KripkeStateProperty(type: .String, value: $0) }),
                    value: fsms
                ),
                "state": KripkeStateProperty(
                    type: .Optional(state.map { KripkeStateProperty(type: .String, value: $0) }),
                    value: state as Any
                )
            ]
            return KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(properties: plist)),
                value: value
            )
        }
        let state = "Ping"
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("S", state)
        )
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("S")
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("E", state)
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("E")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("R", state)
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("R", state, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("R", nil, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("S", state, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("S", nil, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("E", state, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("E", nil, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: state, collapseIfPossible: false),
            property("W", state, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: nil, collapseIfPossible: false),
            property("W", nil, ["0"])
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: false),
            property("W", state)
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: false),
            property("W")
        )
        // swiftlint:enable line_length
    }

    // swiftlint:disable:next function_body_length
    func testPropertyWithMultipleTimeslotsWhenCollapseIfPossibleIsTrue() {
        func strProperty(_ str: String) -> KripkeStateProperty {
            KripkeStateProperty(type: .String, value: str)
        }
        func property(_ marker: String, _ state: String? = nil) -> KripkeStateProperty {
            let value: [String: Any] = [
                "step": marker,
                "fsms": ["0", "3", "6"],
                "state": state as Any
            ]
            let plist: [String: KripkeStateProperty] = [
                "step": KripkeStateProperty(type: .String, value: marker),
                "fsms": KripkeStateProperty(
                    type: .Collection([
                        KripkeStateProperty(type: .String, value: "0"),
                        KripkeStateProperty(type: .String, value: "3"),
                        KripkeStateProperty(type: .String, value: "6")
                    ]),
                    value: ["0", "3", "6"]
                ),
                "state": KripkeStateProperty(
                    type: .Optional(state.map { KripkeStateProperty(type: .String, value: $0) }),
                    value: state as Any
                )
            ]
            return KripkeStateProperty(
                type: .Compound(KripkeStatePropertyList(properties: plist)),
                value: value
            )
        }
        let state = "Ping"
        // swiftlint:disable line_length
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("S", state)
        )
        XCTAssertEqual(
            VerificationStep.startDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("S")
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("E", state)
        )
        XCTAssertEqual(
            VerificationStep.endDelegates(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("E")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("R", state)
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            strProperty("0.Ping.R")
        )
        XCTAssertEqual(
            VerificationStep.takeSnapshotAndStartTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            strProperty("0.R")
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            strProperty("0.Ping.S")
        )
        XCTAssertEqual(
            VerificationStep.startTimeslot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            strProperty("0.S")
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            strProperty("0.Ping.E")
        )
        XCTAssertEqual(
            VerificationStep.execute(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            strProperty("0.E")
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: state, collapseIfPossible: true),
            strProperty("0.Ping.W")
        )
        XCTAssertEqual(
            VerificationStep.executeAndSaveSnapshot(timeslot: timeslot0).property(state: nil, collapseIfPossible: true),
            strProperty("0.W")
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: state, collapseIfPossible: true),
            property("W", state)
        )
        XCTAssertEqual(
            VerificationStep.saveSnapshot(timeslots: timeslots).property(state: nil, collapseIfPossible: true),
            property("W")
        )
        // swiftlint:enable line_length
    }

}
