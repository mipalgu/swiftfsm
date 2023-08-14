import FSM

/// Provides default implementations for required fields within the FSM.
extension FSM {

    /// Calculates the name of the fsm utilising the dynamic type of self.
    public var name: String {
        guard let name = "\(type(of: self))".split(separator: ".").first.map(String.init) else {
            // swiftlint:disable:next line_length
            fatalError(
                "Unable to compute name of FSM with type \(type(of: self)). Please specify a name: let name = \"<MyName>\""
            )
        }
        return name
    }

    /// By default, we assume that there is not a custom suspend state and that
    /// creating a `FiniteStateMachine` from this model will synthesize an empty
    /// suspend state automatically.
    public var suspendState: KeyPath<Self, StateInformation>? { nil }

}

extension FSM where Context: EmptyInitialisable {

    public var initialContext: Context { Context() }

}

extension FSM where Ringlet.Context: EmptyInitialisable {

    public var initialRingletContext: Ringlet.Context { Ringlet.Context() }

}
