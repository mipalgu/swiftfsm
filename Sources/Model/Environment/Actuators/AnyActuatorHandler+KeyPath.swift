import FSM

public extension AnyActuatorHandler {

    /// Create a type-erased actuator handler.
    ///
    /// - Parameter base: The base actuator handler.
    ///
    /// - Parameter keyPath: The key path that associates this actuator with
    /// a value within an environment snapshot.
    init<Base: ActuatorHandler>(
        _ base: Base,
        mapsTo keyPath: WritableKeyPath<Environment, Base.Value?>
    ) {
        self.init(base) {
            $0.pointee[keyPath: keyPath] = $1 as! Base.Value
        }
    }

}
