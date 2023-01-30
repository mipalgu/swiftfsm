public struct SingleMachineArrangement: ArrangementProtocol {

    public let fsms: [Machine]

    public init<FSM: FSMModel>(fsm: FSM) {
        self.fsms = [Machine(wrappedValue: fsm)]
    }

}
