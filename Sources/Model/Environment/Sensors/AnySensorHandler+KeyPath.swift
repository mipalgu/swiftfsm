import FSM

public extension AnySensorHandler {

    init<Base: SensorHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self.init(base) {
            $0.pointee[keyPath: keyPath] = $1 as! Base.Value
        }
    }

}
