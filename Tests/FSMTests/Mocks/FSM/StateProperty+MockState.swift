import FSM

extension StateProperty {

    init<FSMsContext: ContextProtocol, Environment: EnvironmentSnapshot>(
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment> ...,
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<EmptyDataStructure, FSMsContext, Environment>,
                (Root) -> StateInformation
            >] = { [] }
    ) where StateType == AnyMockState<FSMsContext, Environment> {
        self.init(
            wrappedValue: EmptyMockState(),
            name: name,
            uses: environmentVariables,
            transitions: transitions
        )
    }

    init<StatesContext: ContextProtocol, FSMsContext: ContextProtocol, Environment: EnvironmentSnapshot>(
        name: String,
        context _: StatesContext.Type,
        uses environmentVariables: PartialKeyPath<Root.Environment> ...,
        onEntry: @Sendable @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        internal: @Sendable @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @Sendable @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @Sendable @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @Sendable @escaping (inout StateContext<StatesContext, FSMsContext, Environment>) -> Void = { _ in },
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
            uses: environmentVariables,
            transitions: transitions
        )
    }

    init<FSMsContext: ContextProtocol, Environment: EnvironmentSnapshot>(
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment> ...,
        onEntry: @Sendable @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        internal: @Sendable @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onExit: @Sendable @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onSuspend: @Sendable @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
        onResume: @Sendable @escaping (inout StateContext<EmptyDataStructure, FSMsContext, Environment>) -> Void = { _ in },
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
            uses: environmentVariables,
            transitions: transitions
        )
    }

}
