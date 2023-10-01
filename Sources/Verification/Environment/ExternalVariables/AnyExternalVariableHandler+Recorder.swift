import FSM

extension AnyExternalVariableHandler {

    init(recorder: Recorder, base: AnyExternalVariableHandler) {
        self.init(
            base: { base.base },
            id: { base.id },
            saveSnapshot: { base.saveSnapshot(value: $0) },
            takeSnapshot: {
                recorder.read = true
                return base.takeSnapshot()
            },
            updateEnvironment: { base.update(environment: $0, with: $1) }
        )
    }

}
