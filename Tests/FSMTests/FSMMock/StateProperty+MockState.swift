import FSM

extension StateProperty {

    init<FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        @TransitionBuilder transitions:
            () -> [AnyTransition<EmptyMockState<FSMsContext, Environment>, (Root) -> StateInformation>]
                = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(wrappedValue: EmptyMockState(), name: name, transitions: transitions)
    }

    init<StatesContext: DataStructure, FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        onEntry: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        main: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                    CallbackMockState<StatesContext, FSMsContext, Environment>,
                    (Root) -> StateInformation
                >] = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(
            wrappedValue: CallbackMockState(
                onEntry: onEntry,
                main: main,
                onExit: onExit,
                onSuspend: onSuspend,
                onResume: onResume
            ),
            name: name,
            transitions: transitions
        )
    }

}
