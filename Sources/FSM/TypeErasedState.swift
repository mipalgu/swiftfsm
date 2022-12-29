public protocol TypeErasedState {

    associatedtype FSMsContext: DataStructure
    associatedtype Environment: DataStructure

    var base: Any { get }

}
