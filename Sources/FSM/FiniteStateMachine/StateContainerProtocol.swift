public protocol StateContainerProtocol {

    associatedtype StateType: TypeErasedState
    associatedtype RingletsContext: ContextProtocol
    associatedtype FSMsContext: ContextProtocol
    associatedtype Environment: EnvironmentSnapshot
    associatedtype Parameters: DataStructure
    associatedtype Result: DataStructure

    func state(at id: Int) -> FSMState<StateType, Parameters, Result, FSMsContext, Environment>

}
