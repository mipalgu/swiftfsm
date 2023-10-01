public struct FSMHandlers<Environment: EnvironmentSnapshot> {

    public var actuators: [AnyActuatorHandler<Environment>]

    public var externalVariables: [AnyExternalVariableHandler<Environment>]

    public var globalVariables: [AnyGlobalVariableHandler<Environment>]

    public var sensors: [AnySensorHandler<Environment>]

    public init(
        actuators: [AnyActuatorHandler<Environment>],
        externalVariables: [AnyExternalVariableHandler<Environment>],
        globalVariables: [AnyGlobalVariableHandler<Environment>],
        sensors: [AnySensorHandler<Environment>]
    ) {
        self.actuators = actuators
        self.externalVariables = externalVariables
        self.globalVariables = globalVariables
        self.sensors = sensors
    }

}
