import FSM

extension FSMModel {

    // swiftlint:disable:next identifier_name
    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition: @escaping (EmptyMockState<Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<EmptyMockState<Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to state: String,
        canTransition: @escaping (EmptyMockState<Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<EmptyMockState<Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: state, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition: @escaping (CallbackMockState<EmptyDataStructure, Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<CallbackMockState<EmptyDataStructure, Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition(
        to state: String,
        canTransition: @escaping (CallbackMockState<EmptyDataStructure, Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<CallbackMockState<EmptyDataStructure, Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: state, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to keyPath: KeyPath<Self, StateInformation>,
        context _: StatesContext.Type,
        canTransition: @escaping (CallbackMockState<StatesContext, Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<CallbackMockState<StatesContext, Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: keyPath, canTransition: canTransition)
    }

    // swiftlint:disable:next identifier_name
    static func Transition<StatesContext: DataStructure>(
        to state: String,
        context _: StatesContext.Type,
        canTransition: @escaping (CallbackMockState<StatesContext, Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<CallbackMockState<StatesContext, Context, Environment>, (Self) -> StateInformation> {
        AnyTransition(to: state, canTransition: canTransition)
    }

}
