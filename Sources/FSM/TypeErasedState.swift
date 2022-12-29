public protocol TypeErasedState {

    associatedtype Context: FSMContextProtocol

    var base: Any { get }

}
