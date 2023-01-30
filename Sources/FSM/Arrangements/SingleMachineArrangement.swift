public struct SingleMachineArrangement<FSM: FSMModel>: ArrangementProtocol {

    let machine: FSM

    public var fsms: [Machine] {
        [Machine(wrappedValue: machine)]
    }

}
