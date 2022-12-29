import FSM

extension StateProperty {

    init<FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<EmptyDataStructure, FSMsContext, Environment>,
                (Root) -> StateInformation
            >] = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(wrappedValue: EmptyMockState(), name: name, transitions: transitions)
    }

    init<StatesContext: DataStructure, FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        context _: StatesContext.Type,
        onEntry: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        internal: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                    StateContext<StatesContext, FSMsContext, Environment>,
                    (Root) -> StateInformation
                >] = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(
            wrappedValue: CallbackMockState(
                onEntry: onEntry,
                internal: `internal`,
                onExit: onExit,
                onSuspend: onSuspend,
                onResume: onResume
            ),
            name: name,
            transitions: transitions
        )
    }

    init<FSMsContext: DataStructure, Environment: DataStructure>(
        name: String,
        onEntry: @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        internal: @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                    StateContext<EmptyDataStructure, FSMsContext, Environment>,
                    (Root) -> StateInformation
                >] = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(
            wrappedValue: CallbackMockState(
                onEntry: onEntry,
                internal: `internal`,
                onExit: onExit,
                onSuspend: onSuspend,
                onResume: onResume
            ),
            name: name,
            transitions: transitions
        )
    }

}
