@propertyWrapper
public struct StateProperty<StateType: StateProtocol, Root> {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public var transitions: [AnyTransition<StateType, (Root) -> StateInformation>]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        @TransitionBuilder transitions: () -> [AnyTransition<ConcreteState, (Root) -> StateInformation>] = { [] }
    ) where ConcreteState.TypeErasedVersion == StateType, ConcreteState: Nameable {
        self.projectedValue = StateInformation(name: wrappedValue.name)
        self.wrappedValue = wrappedValue.erased
        self.transitions = transitions().map { transition in
            AnyTransition(to: transition.target) {
                transition.canTransition(from: $0 as! ConcreteState)
            }
        }
    }

}
