public protocol FSMData: FiniteStateMachineOperations & Sendable {

    var fsm: Int { get set }

}
