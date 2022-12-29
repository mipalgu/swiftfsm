@propertyWrapper
public struct StateProperty<StateType: TypeErasedState, Root> {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public var transitions:
        [AnyTransition<
            FSMContext<StateType.FSMsContext, StateType.Environment>,
            (Root) -> StateInformation
        >]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
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
        self.transitions = transitions().map { transition in
            AnyTransition(to: transition.target) {
                transition.canTransition(from: StateContext(fsmContext: $0))
            }
        }
    }

}
