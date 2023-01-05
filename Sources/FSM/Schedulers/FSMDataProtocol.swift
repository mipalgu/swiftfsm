public protocol FSMDataProtocol: FiniteStateMachineOperations & Sendable {

    var fsm: Int { get set }

}
