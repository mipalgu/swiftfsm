import FSM

struct Arrangement: ArrangementModel {

    @Machine
    var pingPong = FSMMock()

}
