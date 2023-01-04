import FSM

struct Arrangement: ArrangementModel {

    @Machine
    var pingPong = FSMMock()

    @Slot(fsm: \.$pingPong, timing: (startTime: 0, duration: 20))
    var pingPongTimeslot

    @Group(slots: \.$pingPongTimeslot)
    var group

}
