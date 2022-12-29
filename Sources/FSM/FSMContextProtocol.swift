public protocol FSMContextProtocol: FiniteStateMachineOperations {

    associatedtype FSMsContext: DataStructure
    associatedtype Environment: DataStructure

}
