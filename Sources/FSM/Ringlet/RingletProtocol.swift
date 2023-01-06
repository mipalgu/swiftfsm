public protocol RingletProtocol: ContextUser, EmptyInitialisable {

    associatedtype StateType: TypeErasedState

    associatedtype TransitionType: TransitionProtocol where
        TransitionType.Source == FSMContext<
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >,
        TransitionType.Target == StateID

    func execute(
        id: StateID,
        state: StateType,
        transitions: [TransitionType],
        context: RingletContext<
            StateType,
            Context,
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >
    ) -> StateID

}
