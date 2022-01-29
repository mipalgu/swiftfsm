import swiftfsm

/**
 *  A standard ringlet.
 *
 *  Firstly calls onEntry if we have just transitioned to this state.  If a
 *  transition is possible then the states onExit method is called and the new
 *  state is returned.  If no transitions are possible then the main method is
 *  called and the state is returned.
 */
public final class SonarRinglet: Ringlet, Cloneable, KripkeVariablesModifier {

    internal var Me: SonarFiniteStateMachine!

    public var computedVars: [String: Any] {
        return [
            "shouldExecuteOnEntry": self.Me.currentState != self.Me.previousState
        ]
    }

    public var manipulators: [String : (Any) -> Any] {
        return [:]
    }

    public var validVars: [String: [Any]] {
        return [
            "Me": []
        ]
    }

    /**
     *  Create a new `MiPalRinglet`.
     *
     */
    public init() {}

    /**
     *  Execute the ringlet.
     *
     *  - Parameter state: The `SonarState` that is being executed.
     *
     *  - Returns: A state representing the next state to execute.
     */
    public func execute(state: SonarState) -> SonarState {
        // Call onEntry if we have just transitioned to this state.
        if state != self.Me.previousState {
            state.onEntry()
        }
        // Can we transition to another state?
        if let t = state.transitions.first(where: { $0.canTransition(state) }) {
            // Yes - Exit state and return the new state.
            state.onExit()
            return t.target
        }
        // No - Execute main method and return state.
        state.main()
        return state
    }

    public func clone() -> SonarRinglet {
        let r = SonarRinglet()
        r.Me = self.Me
        return r
    }

}