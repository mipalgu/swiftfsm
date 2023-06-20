public protocol TypeErasedState {

    associatedtype FSMsContext: ContextProtocol
    associatedtype Environment: EnvironmentSnapshot
    associatedtype Parameters: DataStructure
    associatedtype Result: DataStructure

    var base: Any { get }

    func initialContext(fsmContext: FSMContext<FSMsContext, Environment, Parameters, Result>)
        -> AnyStateContext<FSMsContext, Environment, Parameters, Result>

    static var emptyState: Self { get }

}
