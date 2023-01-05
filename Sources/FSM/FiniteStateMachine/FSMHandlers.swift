public struct FSMHandlers<Environment: EnvironmentSnapshot> {

    public var actuators: [PartialKeyPath<Environment>: AnyActuatorHandler<Environment>]

    public var externalVariables: [PartialKeyPath<Environment>: AnyExternalVariableHandler<Environment>]

    public var sensors: [PartialKeyPath<Environment>: AnySensorHandler<Environment>]

}
