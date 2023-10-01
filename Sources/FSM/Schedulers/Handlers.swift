public struct Handlers {

    public var actuators: [AnyActuatorHandler]

    public var externalVariables: [AnyExternalVariableHandler]

    public var globalVariables: [AnyGlobalVariableHandler]

    public var sensors: [AnySensorHandler]

    public init(
        actuators: [AnyActuatorHandler],
        externalVariables: [AnyExternalVariableHandler],
        globalVariables: [AnyGlobalVariableHandler],
        sensors: [AnySensorHandler]
    ) {
        self.actuators = actuators
        self.externalVariables = externalVariables
        self.globalVariables = globalVariables
        self.sensors = sensors
    }

}
