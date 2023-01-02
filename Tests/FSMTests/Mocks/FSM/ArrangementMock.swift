import FSM

struct Arrangement: ArrangementModel {

    @Machine
    var pingPong = FSMMock()

    @Timeslot(fsm: \.$pingPong, startTime: 0, duration: 10)
    var timeslot

}
