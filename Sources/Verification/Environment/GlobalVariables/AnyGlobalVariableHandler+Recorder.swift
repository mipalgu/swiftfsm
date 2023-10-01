import FSM

extension AnyGlobalVariableHandler {

    init(recorder: Recorder, base: AnyGlobalVariableHandler) {
        self.init(
            base: { base.base },
            id: { base.id },
            saveSnapshot: { base.value = $0 },
            takeSnapshot: {
                recorder.read = true
                return base.value
            },
            updateEnvironment: { base.update(environment: $0, with: $1) }
        )
    }

}
