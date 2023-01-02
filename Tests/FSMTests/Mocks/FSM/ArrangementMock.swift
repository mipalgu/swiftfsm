import FSM

struct Arrangement: TTArrangementModel {

    @Machine
    var pingPong = FSMMock()

    @Timeslot(fsm: \.$pingPong, startTime: 0, duration: 20)
    var pingPongTimeslot

}
