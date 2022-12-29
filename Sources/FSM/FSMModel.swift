public protocol FSMModel<StateType>: ContextUser, EnvironmentUser {

    associatedtype Context: DataStructure = EmptyDataStructure

    associatedtype StateType: TypeErasedState
        where StateType.Context.FSMsContext == Context,
            StateType.Context.Environment == Environment

    associatedtype TransitionType: TransitionProtocol
        = AnyTransition<StateType, (Self) -> StateInformation>
        where TransitionType.Source == StateType,
            TransitionType.Target == (Self) -> StateInformation

    var initialState: KeyPath<Self, StateInformation> { get }

}

public extension FSMModel {

    typealias State = StateProperty<StateType, Self>

    typealias Transition<ConcreteState: StateProtocol>
        = AnyTransition<ConcreteState, (Self) -> StateInformation>
            where ConcreteState.TypeErasedVersion == StateType

    typealias StateID = Int

    func id(of keyPath: KeyPath<Self, StateInformation>) -> StateID {
        self[keyPath: keyPath].id
    }

    func id(of state: String) -> StateID {
        StateRegistrar.id(of: state)
    }

}
