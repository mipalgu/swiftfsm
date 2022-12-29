import FSM

extension FSMModel {

    static func Transition(
        to keyPath: KeyPath<Self, StateInformation>,
        canTransition: @escaping (EmptyMockState<Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<EmptyMockState<Context, Environment>, (Self) -> StateInformation> {
        AnyTransition.init(to: keyPath, canTransition: canTransition)
    }

    static func Transition(
        to state: String,
        canTransition: @escaping (EmptyMockState<Context, Environment>) -> Bool = { _ in true }
    ) -> AnyTransition<EmptyMockState<Context, Environment>, (Self) -> StateInformation> {
        AnyTransition.init(to: state, canTransition: canTransition)
    }

}
