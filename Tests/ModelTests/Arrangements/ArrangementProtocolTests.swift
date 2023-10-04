import FSM
import InMemoryVariables
import Mocks
import XCTest

@testable import Model

private struct SimpleArrangement: Arrangement {

    @Actuator
    var countActuator = ActuatorHandlerMock(id: "countActuator", initialValue: 1)

    @ExternalVariable
    var countExternalVariable = ExternalVariableHandlerMock(id: "countExternalVariable", value: 2)

    @GlobalVariable
    var countGlobalVariable = InMemoryGlobalVariable(id: "countGlobalVariable", initialValue: 3)

    @Sensor
    var countSensor = SensorHandlerMock(id: "countSensor", value: 4)

    @Machine
    var mock = FSMMock()

    @Machine
    var mock2 = FSMMock()

    var bool = false

    var integer = 2

}

final class ArrangementProtocolTests: XCTestCase {

    func testDefaultScheduleGetter() {
        let arrangement = SimpleArrangement()
        let schedule = arrangement.defaultSchedule
        XCTAssertEqual("\(type(of: schedule))", "\(AnySchedule<SimpleArrangement>.self)")
        let slots = [arrangement.$mock, arrangement.$mock2]
            .map {
                SlotInformation(fsm: $0, timing: nil)
            }
        XCTAssertEqual(schedule.groups, [GroupInformation(slots: slots)])
    }

}
