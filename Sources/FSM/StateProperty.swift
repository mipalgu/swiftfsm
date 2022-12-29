@propertyWrapper
public struct StateProperty<StateType: TypeErasedState, Root> {

    public let projectedValue: StateInformation

    public var wrappedValue: StateType

    public var transitions: [AnyTransition<StateType, (Root) -> StateInformation>]

    public init<ConcreteState: StateProtocol>(
        wrappedValue: ConcreteState,
        name: String,
        @TransitionBuilder transitions: () -> [AnyTransition<ConcreteState, (Root) -> StateInformation>] = { [] }
    ) where ConcreteState.TypeErasedVersion == StateType {
        self.projectedValue = StateInformation(name: name)
        self.wrappedValue = wrappedValue.erased
        self.transitions = transitions().map { transition in
            AnyTransition(to: transition.target) {
                // swiftlint:disable:next force_cast
                transition.canTransition(from: $0 as! ConcreteState)
            }
        }
    }

}
