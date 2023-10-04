import FSM
import Mocks
import XCTest

@testable import Model

private struct SimpleArrangement: Arrangement, EmptyInitialisable {

    @Machine
    var mock = FSMMock()

    @Machine
    var mock2 = FSMMock()

    var bool = false

    var integer = 2

}

final class ArrangementTests: XCTestCase {

    func testFsmsGetter() {
        let arrangement = SimpleArrangement()
        XCTAssertEqual(arrangement.fsms.map(\.projectedValue), [arrangement.$mock, arrangement.$mock2])
    }

    func testSubArrangementsFSMsGetter() {
        let arrangement = ArrangementOfArrangementMock()
        XCTAssertEqual(arrangement.fsms.count, 2)
        XCTAssertNotEqual(arrangement.fsms[0].projectedValue.id, arrangement.fsms[1].projectedValue.id)
    }

    func testDefaultScheduleGetter() {
        let arrangement = SimpleArrangement()
        let schedule = SimpleArrangement.defaultSchedule
        XCTAssertEqual("\(type(of: schedule))", "\(AnySchedule<SimpleArrangement>.self)")
        let slots = [arrangement.$mock, arrangement.$mock2]
            .map {
                SlotInformation(fsm: $0, timing: nil)
            }
        XCTAssertEqual(schedule.groups, [GroupInformation(slots: slots)])
    }

}
