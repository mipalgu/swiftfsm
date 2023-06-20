public struct FSMHandlers<Environment: EnvironmentSnapshot> {

    public var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>]

    public var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>]

    public var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]

    public init(
        actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>],
        externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>],
        sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]
    ) {
        self.actuators = actuators
        self.externalVariables = externalVariables
        self.sensors = sensors
    }

}
