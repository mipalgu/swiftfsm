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

    mutating func execute(
        id: StateID,
        state: StateType,
        transitions: [TransitionType],
        fsmContext: inout FSMContext<
            StateType.FSMsContext,
            StateType.Environment,
            StateType.Parameters,
            StateType.Result
        >,
        context: inout Context
    ) -> StateID

}
