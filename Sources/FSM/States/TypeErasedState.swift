public protocol TypeErasedState {

    associatedtype FSMsContext: ContextProtocol
    associatedtype Environment: EnvironmentSnapshot
    associatedtype Parameters: DataStructure
    associatedtype Result: DataStructure

    var base: Any { get }

    static var empty: (Sendable, Self) { get }

}
