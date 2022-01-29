import swiftfsm
import SwiftfsmWBWrappers

public final class State_ClearTrigger: SonarState {

    public override var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "gateway": [],
            "clock": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "Me": []
        ]
    }

    fileprivate let gateway: FSMGateway

    public let clock: Timer

    public internal(set) var fsmVars: SonarVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public internal(set) var distance: UInt16 {
        get {
            return fsmVars.distance
        }
        set {
            fsmVars.distance = newValue
        }
    }

    public internal(set) var numLoops: UInt16 {
        get {
            return fsmVars.numLoops
        }
        set {
            fsmVars.numLoops = newValue
        }
    }

    public internal(set) var maxLoops: UInt16 {
        get {
            return fsmVars.maxLoops
        }
        set {
            fsmVars.maxLoops = newValue
        }
    }

    public var SPEED_OF_SOUND: Double {
        get {
            return fsmVars.SPEED_OF_SOUND
        }
    }

    public internal(set) var SCHEDULE_LENGTH: Double {
        get {
            return fsmVars.SCHEDULE_LENGTH
        }
        set {
            fsmVars.SCHEDULE_LENGTH = newValue
        }
    }

    public internal(set) var SONAR_OFFSET: Double {
        get {
            return fsmVars.SONAR_OFFSET
        }
        set {
            fsmVars.SONAR_OFFSET = newValue
        }
    }

    public var echoPinValue: WhiteboardVariable<Bool>.Class {
        get {
            return Me.external_echoPinValue.val
        }
    }

    public internal(set) var triggerPin: WhiteboardVariable<Bool>.Class {
        get {
            return Me.external_triggerPin.val
        }
        set {
            Me.external_triggerPin.val = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<State_ClearTrigger, SonarState>] = [],
        gateway: FSMGateway
,        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { SonarStateTransition($0) }, snapshotSensors: ["echoPinValue"], snapshotActuators: ["triggerPin"])
    }

    public override func onEntry() {
        triggerPin = false
    }

    public override func onExit() {
        numLoops += 1
    }

    public override func main() {
        numLoops += 1
    }

    public override final func clone() -> State_ClearTrigger {
        let transitions: [Transition<State_ClearTrigger, SonarState>] = self.transitions.map { $0.cast(to: State_ClearTrigger.self) }
        let state = State_ClearTrigger(
            "ClearTrigger",
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension State_ClearTrigger: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
