import Model

public struct ScheduleMock: ScheduleModel {

    public typealias Arrangement = ArrangementMock

    @Slot(fsm: \.$pingPong, timing: (startTime: 0, duration: 20))
    public var pingPongTimeslot

    @Group(slots: \.$pingPongTimeslot)
    public var group

    public init() {}

}
