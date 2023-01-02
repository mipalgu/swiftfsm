public protocol TypeErasedState {

    associatedtype FSMsContext: ContextProtocol
    associatedtype Environment: EnvironmentSnapshot

    var base: Any { get }

}
