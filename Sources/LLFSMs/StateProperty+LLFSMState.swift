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
        initialContext: StatesContext,
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
        let onEntryPrint = name + (verbose > 1 ? ".onEntry" : "")
        let onEntry = verbose > 0 ? { print(onEntryPrint); onEntry($0) } : onEntry
        let `internal` = verbose > 1 ? { print(name + ".internal"); `internal`($0) } : `internal`
        let onExit = verbose > 1 ? { print(name + ".onExit"); onExit($0) } : onExit
        let onSuspend = verbose > 1 ? { print(name + ".onSuspend"); onSuspend($0) } : onSuspend
        let onResume = verbose > 1 ? { print(name + ".onResume"); onResume($0) } : onResume
        self.init(
            wrappedValue: CallbackLLFSMState(
                initialContext: initialContext,
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
        let onEntryPrint = name + (verbose > 1 ? ".onEntry" : "")
        let onEntry = verbose > 0 ? { print(onEntryPrint); onEntry($0) } : onEntry
        let `internal` = verbose > 1 ? { print(name + ".internal"); `internal`($0) } : `internal`
        let onExit = verbose > 1 ? { print(name + ".onExit"); onExit($0) } : onExit
        let onSuspend = verbose > 1 ? { print(name + ".onSuspend"); onSuspend($0) } : onSuspend
        let onResume = verbose > 1 ? { print(name + ".onResume"); onResume($0) } : onResume
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
