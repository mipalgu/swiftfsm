import FSM

extension AnyActuatorHandler {

    init(recorder: Recorder, base: AnyActuatorHandler) {
        self.init(
            base: { base.base },
            id: { base.id },
            initialValue: { recorder.forcingValue },
            saveSnapshot: { recorder.writtenValue = $0 },
            updateEnvironment: { base.update(environment: $0, with: $1) }
        )
    }

}
