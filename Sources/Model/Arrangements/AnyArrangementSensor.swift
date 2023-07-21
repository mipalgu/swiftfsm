import FSM

public protocol AnyArrangementSensor {

    func anySensor<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> AnySensorHandler<Environment>

}
