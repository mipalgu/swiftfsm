import swiftfsm

/**
 *  The base class for all states that conform to `MiPalAction`s.
 */
public class SonarState:
    StateType,
    CloneableState,
    MiPalActions,
    Transitionable,
    KripkeVariablesModifier,
    SnapshotListContainer
{

    /**
     *  The name of the state.
     *
     *  - Requires: Must be unique for each state.
     */
    public let name: String

    /**
     *  An array of transitions that this state may use to move to another
     *  state.
     */
    public var transitions: [SonarStateTransition]
    
    public let snapshotSensors: Set<String>?
    
    public let snapshotActuators: Set<String>?

    internal weak var Me: SonarFiniteStateMachine!

    open var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "Me": []
        ]
    }

    /**
     *  Create a new `SonarState`.
     *
     *  - Parameter name: The name of the state.
     *
     *  - transitions: All transitions to other states that this state can use.
     */
    public init(_ name: String, transitions: [SonarStateTransition] = [], snapshotSensors: Set<String>?, snapshotActuators: Set<String>?) {
        self.name = name
        self.transitions = transitions
        self.snapshotSensors = snapshotSensors
        self.snapshotActuators = snapshotActuators
    }

    /**
     *  Does nothing.
     */
    open func onEntry() {}

    /**
     *  Does nothing.
     */
    open func main() {}

    /**
     *  Does nothing.
     */
    open func onExit() {}

    /**
     *  Create a copy of `self`.
     *
     *  - Warning: Child classes should override this method.  If they do not
     *  then the application will crash when trying to generate
     *  `KripkeStructures`.
     */
    open func clone() -> Self {
        fatalError("Please implement your own clone")
    }
    
}