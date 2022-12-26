public protocol FiniteStateMachineProtocol<StateType>: ContextUser, FiniteStateMachineOperations {

    associatedtype Context = EmptyDataStructure

    associatedtype StateType: StateProtocol
        where StateType.Context: Convertible,
            StateType.Context.Source == Context

    associatedtype TransitionType: TransitionProtocol
        = AnyTransition<StateType, (Self) -> StateInformation>
        where TransitionType.Source == StateType,
            TransitionType.Target == (Self) -> StateInformation

    var context: Context { get set }

    var currentState: StateID { get set }

    var initialState: StateID { get }

    var name: String { get }

    mutating func next()

}

public extension FiniteStateMachineProtocol {

    typealias State<ConcreteState: StateProtocol> = StateProperty<ConcreteState, Self>
        where ConcreteState: Nameable,
            ConcreteState.Context: Convertible,
            ConcreteState.Context.Source == Context,
            ConcreteState.TypeErasedVersion == StateType

    typealias Transition<ConcreteState: StateProtocol>
        = AnyTransition<ConcreteState, (Self) -> StateInformation>
            where ConcreteState: Nameable,
                ConcreteState.Context: Convertible,
                ConcreteState.Context.Source == Context,
                ConcreteState.TypeErasedVersion == StateType

    typealias StateID = Int

    func id(of keyPath: KeyPath<Self, StateInformation>) -> StateID {
        self[keyPath: keyPath].id
    }

    func id(of state: String) -> StateID {
        StateRegistrar.id(of: state)
    }

    static func id(of state: String) -> StateID {
        StateRegistrar.id(of: state)
    }

}
