/// An arrangement that contains only a single FSM.
public struct SingleMachineArrangement: ArrangementProtocol {

    /// An array that contains only a single FSM.
    public let fsms: [Machine]

    /// Create a new SingleMachineArrangement.
    ///
    /// - Parameter fsm: The FSM that is contained within this arrangement.
    public init<FSM: Model.FSM>(fsm: FSM) {
        self.fsms = [Machine(wrappedValue: fsm)]
    }

}
