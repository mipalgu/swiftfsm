import FSM

extension AnySensorHandler {

    init(recorder: Recorder, base: AnySensorHandler) {
        self.init(
            base: { base.base },
            id: { base.id },
            takeSnapshot: {
                recorder.read = true
                return base.takeSnapshot()
            },
            updateEnvironment: { base.update(environment: $0, with: $1) }
        )
    }

}
