public protocol FiniteStateMachineProtocol<StateType>: ContextUser, FiniteStateMachineOperations {

    associatedtype StateType: StateProtocol
        where StateType.Context: Convertible,
            StateType.Context.Source == Context

    var context: Context { get set }

    var currentState: StateType { get set }

    var initialState: StateType { get }

    var name: String { get }

    mutating func next()

}

public extension FiniteStateMachineProtocol {

    typealias State<ConcreteState: StateProtocol> = StateProperty<ConcreteState>
        where ConcreteState.Context: Convertible,
            ConcreteState.Context.Source == Context,
            ConcreteState.TypeErasedVersion == StateType

}
