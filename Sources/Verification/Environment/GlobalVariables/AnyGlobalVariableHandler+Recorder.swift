import FSM

extension AnyGlobalVariableHandler {

    init(recorder: Recorder, base: AnyGlobalVariableHandler) {
        self.init(
            base: { base.base },
            id: { base.id },
            saveSnapshot: {
                recorder.writtenValue = $0
            },
            takeSnapshot: {
                recorder.read = true
                return recorder.forcingValue
            },
            updateEnvironment: { base.update(environment: $0, with: $1) }
        )
    }

}
