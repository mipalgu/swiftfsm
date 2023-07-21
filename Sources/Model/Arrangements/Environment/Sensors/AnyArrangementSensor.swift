import FSM

public protocol AnyArrangementSensor {

    func anySensor<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> (PartialKeyPath<Environment>, AnySensorHandler<Environment>)

}
