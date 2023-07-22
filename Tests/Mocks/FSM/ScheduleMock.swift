import FSM
import Model

public struct ScheduleMock: Schedule, EmptyInitialisable {

    public typealias Arrangement = ArrangementMock

    @Slot(fsm: \.$pingPong, timing: (startTime: 0, duration: 20))
    public var pingPongTimeslot

    @Group(slots: \.$pingPongTimeslot)
    public var group

    public init() {}

}
