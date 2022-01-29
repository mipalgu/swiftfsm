import swiftfsm
import SwiftfsmWBWrappers

internal final class SonarFiniteStateMachine: MachineProtocol {

    public typealias _StateType = SonarState

    fileprivate var allStates: [String: SonarState] {
        var stateCache: [String: SonarState] = [:]
        func fetchAllStates(fromState state: SonarState) {
            if stateCache[state.name] != nil {
                return
            }
            stateCache[state.name] = state
            state.transitions.forEach {
                fetchAllStates(fromState: $0.target)
            }
        }
        fetchAllStates(fromState: self.initialState)
        fetchAllStates(fromState: self.suspendState)
        fetchAllStates(fromState: self.exitState)
        return stateCache
    }

    public var computedVars: [String: Any] {
        return [
            "sensors": Dictionary<String, Any>(uniqueKeysWithValues: self.sensors.map {
                ($0.name, $0.val)
            }),
            "actuators": Dictionary<String, Any>(uniqueKeysWithValues: self.actuators.map {
                ($0.name, $0.val)
            }),
            "externalVariables": Dictionary<String, Any>(uniqueKeysWithValues: self.externalVariables.map {
                ($0.name, $0.val)
            }),
            "currentState": self.currentState.name,
            "fsmVars": self.fsmVars.vars,
            "states": self.allStates,
        ]
    }

    /**
     * All external variables used by the machine.
     */
    public var externalVariables: [AnySnapshotController] {
        get {
            return []
        } set {
            for external in newValue {
                switch external.name {
                default:
                    continue
                }
            }
        }
    }

    public var sensors: [AnySnapshotController] {
        get {
            return [AnySnapshotController(self.external_echoPinValue)]
        } set {
            for external in newValue {
                switch external.name {
                case self.external_echoPinValue.name:
                    self.external_echoPinValue.val = external.val as! WhiteboardVariable<Bool>.Class
                default:
                    continue
                }
            }
        }
    }

    public var actuators: [AnySnapshotController] {
        get {
            return [AnySnapshotController(self.external_echoPin), AnySnapshotController(self.external_triggerPin)]
        } set {
            for external in newValue {
                switch external.name {
                case self.external_echoPin.name:
                    self.external_echoPin.val = external.val as! WhiteboardVariable<Bool>.Class
                case self.external_triggerPin.name:
                    self.external_triggerPin.val = external.val as! WhiteboardVariable<Bool>.Class
                default:
                    continue
                }
            }
        }
    }

    public var snapshotSensors: [AnySnapshotController] {
        guard let snapshotSensors = self.currentState.snapshotSensors else {
            return []
        }
        return snapshotSensors.map { (label: String) -> AnySnapshotController in
            switch label {
            case "echoPinValue":
                return AnySnapshotController(self.external_echoPinValue)
            default:
                fatalError("Unable to find sensor \(label).")
            }
        }
    }

    public var snapshotActuators: [AnySnapshotController] {
        guard let snapshotActuators = self.currentState.snapshotActuators else {
            return []
        }
        return snapshotActuators.map { (label: String) -> AnySnapshotController in
            switch label {
            case "echoPin":
                return AnySnapshotController(self.external_echoPin)
            case "triggerPin":
                return AnySnapshotController(self.external_triggerPin)
            default:
                fatalError("Unable to find actuator \(label).")
            }
        }
    }

    public var validVars: [String: [Any]] {
        return [
            "currentState": [],
            "exitState": [],
            "externalVariables": [],
            "sensors": [],
            "actuators": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "fsmVars": [],
            "initialPreviousState": [],
            "initialState": [],
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "external_echoPin": [],
            "external_triggerPin": [],
            "external_echoPinValue": [],
        ]
    }

    /**
     *  The state that is currently executing.
     */
    public var currentState: SonarState

    /**
     *  The state that is used to exit the FSM.
     */
    public private(set) var exitState: SonarState

    /**
     * All FSM variables used by the machine.
     */
    public let fsmVars: SimpleVariablesContainer<SonarVars>

    /**
     *  The initial state of the previous state.
     *
     *  `previousState` is set to this value on restart.
     */
    public private(set) var initialPreviousState: SonarState

    /**
     *  The starting state of the FSM.
     */
    public private(set) var initialState: SonarState

    /**
     *  The name of the FSM.
     *
     *  - Warning: This must be unique between FSMs.
     */
    public let name: String

    /**
     *  The last state that was executed.
     */
    public var previousState: SonarState

    /**
     *  An instance of `Ringlet` that is used to execute the states.
     */
    public fileprivate(set) var ringlet: SonarRinglet

    fileprivate let submachineFunctions: [() -> AnyControllableFiniteStateMachine]

    /**
     * All submachines of this machine.
     */
    public var submachines: [AnyControllableFiniteStateMachine] {
        get {
            return self.submachineFunctions.map { $0() }
        } set {}    }

    /**
     *  The state that was the `currentState` before the FSM was suspended.
     */
    public var suspendedState: SonarState?

    /**
     *  The state that is set to `currentState` when the FSM is suspended.
     */
    public private(set) var suspendState: SonarState

    public var external_echoPin: WhiteboardVariable<Bool>

    public var external_triggerPin: WhiteboardVariable<Bool>

    public var external_echoPinValue: WhiteboardVariable<Bool>

    internal init(
        name: String,
        initialState: SonarState,
        external_echoPin: WhiteboardVariable<Bool>,
        external_triggerPin: WhiteboardVariable<Bool>,
        external_echoPinValue: WhiteboardVariable<Bool>,
        fsmVars: SimpleVariablesContainer<SonarVars>,
        ringlet: SonarRinglet,
        initialPreviousState: SonarState,
        suspendedState: SonarState?,
        suspendState: SonarState,
        exitState: SonarState,
        submachines: [() -> AnyControllableFiniteStateMachine]
    ) {
        self.currentState = initialState
        self.exitState = exitState
        self.external_echoPin = external_echoPin
        self.external_triggerPin = external_triggerPin
        self.external_echoPinValue = external_echoPinValue
        self.fsmVars = fsmVars
        self.initialState = initialState
        self.initialPreviousState = initialPreviousState
        self.name = name
        self.previousState = initialPreviousState
        self.ringlet = ringlet
        self.submachineFunctions = submachines
        self.suspendedState = suspendedState
        self.suspendState = suspendState
        self.allStates.forEach { $1.Me = self }
        self.ringlet.Me = self
    }

    public func clone() -> SonarFiniteStateMachine {
        var stateCache: [String: SonarState] = [:]
        let allStates = self.allStates
        self.fsmVars.vars = self.fsmVars.vars.clone()
        var fsm = SonarFiniteStateMachine(
            name: self.name,
            initialState: self.initialState.clone(),
            external_echoPin: self.external_echoPin.clone(),
            external_triggerPin: self.external_triggerPin.clone(),
            external_echoPinValue: self.external_echoPinValue.clone(),
            fsmVars: SimpleVariablesContainer(vars: self.fsmVars.vars.clone()),
            ringlet: self.ringlet.clone(),
            initialPreviousState: self.initialPreviousState.clone(),
            suspendedState: self.suspendedState.map { $0.clone() },
            suspendState: self.suspendState.clone(),
            exitState: self.exitState.clone(),
            submachines: self.submachineFunctions
        )
        func apply(_ state: SonarState) -> SonarState {
            if let s = stateCache[state.name] {
                return s
            }
            var state = state
            state.Me = fsm
            stateCache[state.name] = state
            state.transitions = state.transitions.map {
                if $0.target == state {
                    return $0
                }
                guard let target = allStates[$0.target.name] else {
                    return $0
                }
                return $0.map { _ in apply(target.clone()) }
            }
            return state
        }
        fsm.initialState = apply(fsm.initialState)
        fsm.initialPreviousState = apply(fsm.initialPreviousState)
        fsm.suspendedState = fsm.suspendedState.map { apply($0) }
        fsm.suspendState = apply(fsm.suspendState)
        fsm.exitState = apply(fsm.exitState)
        fsm.currentState = apply(self.currentState.clone())
        fsm.previousState = apply(self.previousState.clone())
        return fsm
    }

}

extension SonarFiniteStateMachine: CustomStringConvertible {

    var description: String {
        return """
            {
                name: \(self.name),
                external_echoPin: \(self.external_echoPin),
                external_triggerPin: \(self.external_triggerPin),
                external_echoPinValue: \(self.external_echoPinValue),
                fsmVars: \(self.fsmVars.vars),
                initialState: \(self.initialState.name),
                currentState: \(self.currentState.name),
                previousState: \(self.previousState.name),
                suspendState: \(self.suspendState.name),
                suspendedState: \(self.suspendedState.map { $0.name }),
                exitState: \(self.exitState.name),
                states: \(self.allStates)
            }
            """
    }

}
