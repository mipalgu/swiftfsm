import FSM

struct ArrangementMock: ArrangementModel {

    @Machine
    var pingPong = FSMMock()

}

struct Schedule: ScheduleModel {

    let arrangement = ArrangementMock()

    @Slot(fsm: \.$pingPong, timing: (startTime: 0, duration: 20))
    var pingPongTimeslot

    @Group(slots: \.$pingPongTimeslot)
    var group

}
