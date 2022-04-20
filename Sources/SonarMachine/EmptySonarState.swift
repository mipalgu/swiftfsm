import swiftfsm

public final class EmptySonarState: SonarState {

    public init(_ name: String, transitions: [Transition<EmptySonarState, SonarState>] = []) {
        super.init(name, transitions: transitions.map { SonarStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptySonarState {
        let transitions: [Transition<EmptySonarState, SonarState>] = self.transitions.map { $0.cast(to: EmptySonarState.self) }
        return EmptySonarState(self.name, transitions: transitions)
    }

}
