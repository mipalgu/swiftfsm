public protocol TypeErasedState {

    associatedtype FSMsContext: DataStructure
    associatedtype Environment: EnvironmentSnapshot

    var base: Any { get }

}
