/// Conforming types are responsible for defining how a value that can be saved
/// to the environment.
public protocol ActuatorHandler: EnvironmentHandler where Value: ActuatorValue {

    /// The initial value of the actuator.
    var initialValue: Value { get }

    /// Save a value to the environment.
    ///
    /// - Parameter value: The value to save.
    func saveSnapshot(value: Value)

}
