import FSM

@propertyWrapper
public struct StateProperty<StateType: TypeErasedState, Root: FSM>: AnyStateProperty {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public let environmentVariables: [PartialKeyPath<Root.Environment>]

    public var transitions:
        [AnyTransition<
            AnyStateContext<
                StateType.FSMsContext, StateType.Environment, StateType.Parameters, StateType.Result
            >,
            (Root) -> StateInformation
        >]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment>...,
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<
                    ConcreteState.Context,
                    StateType.FSMsContext,
                    StateType.Environment,
                    StateType.Parameters,
                    StateType.Result
                >,
                (Root) -> StateInformation
            >] = { [] }
    )
    where
        ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment,
        ConcreteState.Parameters == StateType.Parameters,
        ConcreteState.Result == StateType.Result
    {
        self.init(
            wrappedValue: wrappedValue,
            name: name,
            uses: environmentVariables,
            transitions: transitions
        )
    }

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
        uses environmentVariables: [PartialKeyPath<Root.Environment>],
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                StateContext<
                    ConcreteState.Context,
                    StateType.FSMsContext,
                    StateType.Environment,
                    StateType.Parameters,
                    StateType.Result
                >,
                (Root) -> StateInformation
            >] = { [] }
    )
    where
        ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment,
        ConcreteState.Parameters == StateType.Parameters,
        ConcreteState.Result == StateType.Result
    {
        self.projectedValue = StateInformation(name: name)
        self.wrappedValue = wrappedValue.erased
        self.environmentVariables = environmentVariables
        self.transitions = transitions()
            .map { transition in
                AnyTransition(to: transition.target) {
                    transition.canTransition(
                        from: unsafeDowncast(
                            $0,
                            to: StateContext<
                                ConcreteState.Context,
                                ConcreteState.FSMsContext,
                                ConcreteState.Environment,
                                ConcreteState.Parameters,
                                ConcreteState.Result
                            >
                            .self
                        )
                    )
                }
            }
    }

}

extension StateProperty {

    public var erasedEnvironmentVariables: Any {
        environmentVariables as Any
    }

    public var erasedState: Sendable {
        wrappedValue as Sendable
    }

    public var information: StateInformation {
        projectedValue
    }

    public func erasedTransitions(for root: Any) -> Sendable {
        guard let root = root as? Root else {
            fatalError("Cannot convert `root` in erasedTransition call to `Root`.")
        }
        let newTransitions = transitions.map {
            $0.map { $0(root).id }
        }
        return newTransitions as Sendable
    }

}
