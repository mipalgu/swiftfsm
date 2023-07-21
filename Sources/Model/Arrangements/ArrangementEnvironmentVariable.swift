import FSM

/// A property wrapper that wraps an `EnvironmentHandler` within an autoclosure
/// to allow new instances of the handler to be created when required.
@propertyWrapper
public struct ArrangementEnvironmentVariable<Handler: EnvironmentHandler> {

    /// A function that creates a new Handler.
    private let make: () -> Handler

    /// Retrieve a new handler instance.
    public var wrappedValue: Handler {
        make()
    }

    /// Create a new environment variable.
    ///
    /// - Parameter wrappedValue: A function that creates a new handler.
    public init(wrappedValue: @autoclosure @escaping () -> Handler) {
        self.make = wrappedValue
    }

}

extension ArrangementEnvironmentVariable: AnyArrangementActuator where Handler: ActuatorHandler {

    public func anyActuator<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> AnyActuatorHandler<Environment>
    {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolActuatorProperty<Handler.Value>>.self
        )
        return AnyActuatorHandler(wrappedValue, mapsTo: actualKeyPath.appending(path: \.wrappedValue))
    }

}

extension ArrangementEnvironmentVariable: AnyArrangementExternalVariable
    where Handler: ExternalVariableHandler {

    public func anyExternalVariable<Environment: EnvironmentSnapshot>(
        mapsTo keyPath: PartialKeyPath<Environment>
    ) -> AnyExternalVariableHandler<Environment> {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolExternalVariableProperty<Handler.Value>>.self
        )
        return AnyExternalVariableHandler(wrappedValue, mapsTo: actualKeyPath.appending(path: \.wrappedValue))
    }

}

extension ArrangementEnvironmentVariable: AnyArrangementSensor where Handler: SensorHandler {

    public func anySensor<Environment: EnvironmentSnapshot>(
        mapsTo keyPath: PartialKeyPath<Environment>
    ) -> AnySensorHandler<Environment> {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolSensorProperty<Handler.Value>>.self
        )
        return AnySensorHandler(wrappedValue, mapsTo: actualKeyPath.appending(path: \.wrappedValue))
    }

}
