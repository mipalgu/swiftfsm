import FSM

final class VerificationContext {

    private let originalHandlers: Handlers

    lazy var actuatorRecorders: [Recorder] = {
        originalHandlers.actuators.map { Recorder(forcingValue: $0.base.initialValue) }
    }()

    lazy var externalVariableRecorders: [Recorder] = {
        originalHandlers.externalVariables.map { Recorder(forcingValue: $0.base.nonNilValue) }
    }()

    lazy var globalVariableRecorders: [Recorder] = {
        originalHandlers.globalVariables.map { Recorder(forcingValue: $0.base.nonNilValue) }
    }()

    lazy var sensorRecorders: [Recorder] = {
        originalHandlers.sensors.map { Recorder(forcingValue: $0.base.nonNilValue) }
    }()

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

    var executable: ExecutableType

    init(executable: ExecutableType) {
        self.executable = executable
        let handlers = executable.executable.handlers
        self.originalHandlers = Handlers(
            actuators: handlers.actuators,
            externalVariables: handlers.externalVariables,
            globalVariables: handlers.globalVariables,
            sensors: handlers.sensors
        )
    }

}
