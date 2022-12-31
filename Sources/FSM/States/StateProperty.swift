@propertyWrapper
public struct StateProperty<StateType: TypeErasedState, Root: FSMModel> {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public let environmentVariables: [PartialKeyPath<Root.Environment>]

    public var transitions:
        [AnyTransition<
            FSMContext<StateType.FSMsContext, StateType.Environment>,
            (Root) -> StateInformation
        >]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment> ...,
        @TransitionBuilder transitions:
            () -> [AnyTransition<
                    StateContext<ConcreteState.Context, StateType.FSMsContext, StateType.Environment>,
                    (Root) -> StateInformation
                >] = { [] }
    ) where ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment {
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
                    StateContext<ConcreteState.Context, StateType.FSMsContext, StateType.Environment>,
                    (Root) -> StateInformation
                >] = { [] }
    ) where ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment {
        self.projectedValue = StateInformation(name: name)
        self.wrappedValue = wrappedValue.erased
        self.environmentVariables = environmentVariables
        self.transitions = transitions().map { transition in
            AnyTransition(to: transition.target) {
                transition.canTransition(from: StateContext(fsmContext: $0))
            }
        }
    }

}
