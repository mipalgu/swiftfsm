public protocol FSMModel<StateType>: ContextUser {

    associatedtype Context = EmptyDataStructure

    associatedtype StateType: StateProtocol
        where StateType.Context: Convertible,
            StateType.Context.Source == Context

    associatedtype TransitionType: TransitionProtocol
        = AnyTransition<StateType, (Self) -> StateInformation>
        where TransitionType.Source == StateType,
            TransitionType.Target == (Self) -> StateInformation

    var initialState: StateID { get }

}

public extension FSMModel {

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

}
