@propertyWrapper
public struct StateProperty<ConcreteState: StateProtocol> {

    public var projectedValue: Self { self }

    public var wrappedValue: ConcreteState

    public var transitions: [AnyTransition<ConcreteState, Int>]

    public init(
        name: String,
        @TransitionBuilder transitions: () -> [AnyTransition<ConcreteState, Int>]
    ) {
        self.wrappedValue = ConcreteState(name: name)
        self.transitions = transitions()
    }

}
