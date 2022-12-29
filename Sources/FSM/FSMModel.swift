public protocol FSMModel<StateType>: ContextUser {

    associatedtype Context: DataStructure = EmptyDataStructure

    associatedtype Environment: EnvironmentVariables = EmptyEnvironment

    associatedtype StateType: TypeErasedState
        where StateType.FSMsContext == Context,
            StateType.Environment == Environment.Data

    var initialState: KeyPath<Self, StateInformation> { get }

}

public extension FSMModel {

    typealias State = StateProperty<StateType, Self>

    typealias StateID = Int

    // swiftlint:disable:next identifier_name
    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition: @escaping (StateContext<EmptyDataStructure, Context, Environment.Data>) -> Bool = { _ in true }
    ) -> AnyTransition<StateContext<EmptyDataStructure, Context, Environment.Data>, (Self) -> StateInformation> {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to state: String,
        canTransition:
            @escaping (StateContext<EmptyDataStructure, Context, Environment.Data>) -> Bool = { _ in true }
    ) -> AnyTransition<StateContext<EmptyDataStructure, Context, Environment.Data>, (Self) -> StateInformation> {
        AnyTransition(to: state, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to keyPath: KeyPath<Self, StateInformation>,
        context _: StatesContext.Type,
        canTransition: @escaping (StateContext<StatesContext, Context, Environment.Data>) -> Bool = { _ in true }
    ) -> AnyTransition<StateContext<StatesContext, Context, Environment.Data>, (Self) -> StateInformation> {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to state: String,
        context _: StatesContext.Type,
        canTransition: @escaping (StateContext<StatesContext, Context, Environment.Data>) -> Bool = { _ in true }
    ) -> AnyTransition<StateContext<StatesContext, Context, Environment.Data>, (Self) -> StateInformation> {
        AnyTransition(to: state, canTransition: canTransition)
    }

    func id(of keyPath: KeyPath<Self, StateInformation>) -> StateID {
        self[keyPath: keyPath].id
    }

    func id(of state: String) -> StateID {
        StateRegistrar.id(of: state)
    }

}
