#if canImport(Model)

import FSM
import Model

extension StateProperty {

    public init<
        FSMsContext: ContextProtocol,
        Environment: EnvironmentSnapshot,
        Parameters: DataStructure,
        Result: DataStructure
    >(
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment>...,
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>,
                (Root) -> StateInformation
            >] = { [] }
    ) where StateType == AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        self.init(
            wrappedValue: EmptyLLFSMState(),
            name: name,
            uses: environmentVariables,
            transitions: transitions
        )
    }

    public init<
        StatesContext: ContextProtocol,
        FSMsContext: ContextProtocol,
        Environment: EnvironmentSnapshot,
        Parameters: DataStructure,
        Result: DataStructure
    >(
        name: String,
        context _: StatesContext.Type,
        uses environmentVariables: PartialKeyPath<Root.Environment>...,
        onEntry:
            @Sendable
        @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        internal:
            @Sendable
        @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onExit:
            @Sendable
        @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onSuspend:
            @Sendable
        @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onResume:
            @Sendable
        @escaping (StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<StatesContext, FSMsContext, Environment, Parameters, Result>,
                (Root) -> StateInformation
            >] = { [] }
    ) where StateType == AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        let onEntry = verbose > 0 ? { print(name); onEntry($0) } : onEntry
        let `internal` = verbose > 0 ? { print(name); `internal`($0) } : `internal`
        let onExit = verbose > 0 ? { print(name); onExit($0) } : onExit
        let onSuspend = verbose > 0 ? { print(name); onSuspend($0) } : onSuspend
        let onResume = verbose > 0 ? { print(name); onResume($0) } : onResume
        self.init(
            wrappedValue: CallbackLLFSMState(
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

    public init<
        FSMsContext: ContextProtocol,
        Environment: EnvironmentSnapshot,
        Parameters: DataStructure,
        Result: DataStructure
    >(
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment>...,
        onEntry:
            @Sendable
        @escaping (StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        internal:
            @Sendable
        @escaping (StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onExit:
            @Sendable
        @escaping (StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onSuspend:
            @Sendable
        @escaping (StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        onResume:
            @Sendable
        @escaping (StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>)
            -> Void = { _ in },
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<EmptyDataStructure, FSMsContext, Environment, Parameters, Result>,
                (Root) -> StateInformation
            >] = { [] }
    ) where StateType == AnyLLFSMState<FSMsContext, Environment, Parameters, Result> {
        let onEntry = verbose > 0 ? { print(name); onEntry($0) } : onEntry
        let `internal` = verbose > 0 ? { print(name); `internal`($0) } : `internal`
        let onExit = verbose > 0 ? { print(name); onExit($0) } : onExit
        let onSuspend = verbose > 0 ? { print(name); onSuspend($0) } : onSuspend
        let onResume = verbose > 0 ? { print(name); onResume($0) } : onResume
        self.init(
            wrappedValue: CallbackLLFSMState(
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

#endif
