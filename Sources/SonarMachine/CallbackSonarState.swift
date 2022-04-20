import swiftfsm

public final class CallbackSonarState: SonarState {

    private let _onEntry: () -> Void

    private let _onExit: () -> Void

    private let _main: () -> Void

    public init(
        _ name: String,
        transitions: [Transition<CallbackSonarState, SonarState>] = [],
        snapshotSensors: Set<String>?,
        snapshotActuators: Set<String>?,
        onEntry: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {},
        main: @escaping () -> Void = {}
    ) {
        self._onEntry = onEntry
        self._onExit = onExit
        self._main = main
        super.init(name, transitions: transitions.map { SonarStateTransition($0) }, snapshotSensors: snapshotSensors, snapshotActuators: snapshotActuators)
    }

    public final override func onEntry() {
        self._onEntry()
    }

    public final override func onExit() {
        self._onExit()
    }

    public final override func main() {
        self._main()
    }

    public override final func clone() -> CallbackSonarState {
        let transitions: [Transition<CallbackSonarState, SonarState>] = self.transitions.map { $0.cast(to: CallbackSonarState.self) }
        return CallbackSonarState(self.name, transitions: transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
