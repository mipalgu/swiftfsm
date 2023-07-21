import FSM

public protocol AnyArrangementActuator {

    func anyActuator<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> AnyActuatorHandler<Environment>

}
