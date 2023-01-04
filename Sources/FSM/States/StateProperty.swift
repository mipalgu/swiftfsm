@propertyWrapper
public struct StateProperty<StateType: TypeErasedState, Root: FSMModel>: AnyStateProperty {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public let environmentVariables: [PartialKeyPath<Root.Environment>]

    public let context: Sendable

    public var transitions:
        [AnyTransition<
            FSMContext<StateType.FSMsContext, StateType.Environment, StateType.Parameters, StateType.Result>,
            (Root) -> StateInformation
        >]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
        uses environmentVariables: PartialKeyPath<Root.Environment> ...,
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
    ) where ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment,
        ConcreteState.Parameters == StateType.Parameters,
        ConcreteState.Result == StateType.Result {
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
    ) where ConcreteState.TypeErasedVersion == StateType,
        ConcreteState.FSMsContext == StateType.FSMsContext,
        ConcreteState.Environment == StateType.Environment,
        ConcreteState.Parameters == StateType.Parameters,
        ConcreteState.Result == StateType.Result {
        self.projectedValue = StateInformation(name: name)
        self.wrappedValue = wrappedValue.erased
        self.environmentVariables = environmentVariables
        self.context = ConcreteState.Context()
        self.transitions = transitions().map { transition in
            AnyTransition(to: transition.target) {
                transition.canTransition(from: StateContext(fsmContext: $0))
            }
        }
    }

}

public extension StateProperty {

    var erasedEnvironmentVariables: Any {
        environmentVariables as Any
    }

    var erasedState: Sendable {
        wrappedValue as Sendable
    }

    var information: StateInformation {
        projectedValue
    }

    func erasedTransitions(for root: Any) -> Sendable {
        guard let root = root as? Root else {
            fatalError("Cannot convert `root` in erasedTransition call to `Root`.")
        }
        let newTransitions = transitions.map {
            $0.map { $0(root).id }
        }
        return newTransitions as Sendable
    }

}
