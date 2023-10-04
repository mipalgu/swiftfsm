import FSM

final class VerificationContext {

    private let originalHandlers: Handlers

    let actuatorRecorders: [Recorder]

    let externalVariableRecorders: [Recorder]

    let globalVariableRecorders: [Recorder]

    let sensorRecorders: [Recorder]

    lazy var recorderHandlers: Handlers = {
        let actuators = originalHandlers.actuators.enumerated().map {
            AnyActuatorHandler(recorder: actuatorRecorders[$0], base: $1)
        }
        let externalVariables = originalHandlers.externalVariables.enumerated().map {
            AnyExternalVariableHandler(recorder: externalVariableRecorders[$0], base: $1)
        }
        let globalVariables = originalHandlers.globalVariables.enumerated().map {
            AnyGlobalVariableHandler(recorder: globalVariableRecorders[$0], base: $1)
        }
        let sensors = originalHandlers.sensors.enumerated().map {
            AnySensorHandler(recorder: sensorRecorders[$0], base: $1)
        }
        return Handlers(
            actuators: actuators,
            externalVariables: externalVariables,
            globalVariables: globalVariables,
            sensors: sensors
        )
    }()

    var information: FSMInformation

    var cloned: VerificationContext {
        VerificationContext(
            information: information,
            originalHandlers: originalHandlers,
            actuatorRecorders: actuatorRecorders.map(\.cloned),
            externalVariableRecorders: externalVariableRecorders.map(\.cloned),
            globalVariableRecorders: globalVariableRecorders.map(\.cloned),
            sensorRecorders: sensorRecorders.map(\.cloned)
        )
    }

    convenience init(information: FSMInformation, handlers: Handlers) {
        self.init(
            information: information,
            originalHandlers: Handlers(
                actuators: handlers.actuators,
                externalVariables: handlers.externalVariables,
                globalVariables: handlers.globalVariables,
                sensors: handlers.sensors
            ),
            actuatorRecorders: handlers.actuators.map { Recorder(forcingValue: $0.base.initialValue) },
            externalVariableRecorders: handlers.externalVariables.map {
                Recorder(forcingValue: $0.base.nonNilValue)
            },
            globalVariableRecorders: handlers.globalVariables.map {
                Recorder(forcingValue: $0.base.nonNilValue)
            },
            sensorRecorders: handlers.sensors.map { Recorder(forcingValue: $0.base.nonNilValue) }
        )
    }

    private init(
        information: FSMInformation,
        originalHandlers: Handlers,
        actuatorRecorders: [Recorder],
        externalVariableRecorders: [Recorder],
        globalVariableRecorders: [Recorder],
        sensorRecorders: [Recorder]
    ) {
        self.information = information
        self.originalHandlers = originalHandlers
        self.actuatorRecorders = actuatorRecorders
        self.externalVariableRecorders = externalVariableRecorders
        self.globalVariableRecorders = globalVariableRecorders
        self.sensorRecorders = sensorRecorders
    }

    func resetReads() {
        actuatorRecorders.forEach { $0.resetRead() }
        externalVariableRecorders.forEach { $0.resetRead() }
        globalVariableRecorders.forEach { $0.resetRead() }
        sensorRecorders.forEach { $0.resetRead() }
    }

    func resetWrites() {
        actuatorRecorders.forEach { $0.resetWrite() }
        externalVariableRecorders.forEach { $0.resetWrite() }
        globalVariableRecorders.forEach { $0.resetWrite() }
        sensorRecorders.forEach { $0.resetWrite() }
    }

    func reset() {
        actuatorRecorders.forEach { $0.reset() }
        externalVariableRecorders.forEach { $0.reset() }
        globalVariableRecorders.forEach { $0.reset() }
        sensorRecorders.forEach { $0.reset() }
    }

}
