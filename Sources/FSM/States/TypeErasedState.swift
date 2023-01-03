public protocol TypeErasedState {

    associatedtype FSMsContext: ContextProtocol
    associatedtype Environment: EnvironmentSnapshot

    var base: Any { get }

    static var empty: (Sendable, Self) { get }

}
