import FSM

public extension AnySensorHandler {

    init<Base: SensorHandler, Environment: EnvironmentSnapshot>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self.init(base) {
            $0.assumingMemoryBound(to: Environment.self).pointee[keyPath: keyPath] = $1 as! Base.Value
        }
    }

}
