public protocol RingletProtocol: ContextUser, EmptyInitialisable {

    associatedtype StateType: TypeErasedState

    associatedtype TransitionType: TransitionProtocol
    where
        TransitionType.Source == AnyStateContext<
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >,
        TransitionType.Target == StateID

    func execute(
        context: SchedulerContext<
            StateType,
            Context,
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >
    ) -> StateID

}
