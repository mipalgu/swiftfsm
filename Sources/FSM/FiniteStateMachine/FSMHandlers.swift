public struct FSMHandlers<Environment: EnvironmentSnapshot> {

    public var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>]

    public var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>]

    public var globalVariables: [PartialKeyPath<Environment>: AnyGlobalVariableHandler<Environment>]

    public var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]

    public init(
        actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>],
        externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>],
        globalVariables: [PartialKeyPath<Environment>: AnyGlobalVariableHandler<Environment>],
        sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]
    ) {
        self.actuators = actuators
        self.externalVariables = externalVariables
        self.globalVariables = globalVariables
        self.sensors = sensors
    }

}
