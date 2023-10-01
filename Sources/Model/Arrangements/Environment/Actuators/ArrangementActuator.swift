import FSM

/// A property wrapper that wraps an `EnvironmentHandler` within an autoclosure
/// to allow new instances of the handler to be created when required.
@propertyWrapper
public struct ArrangementActuator<Handler: ActuatorHandler>: AnyArrangementActuator {

    /// A function that creates a new Handler.
    private let make: () -> Handler

    /// Retrieve a new handler instance.
    public var wrappedValue: Handler {
        make()
    }

    /// Returns self.
    public var projectedValue: any AnyArrangementActuator {
        self
    }

    /// Create a new environment variable.
    ///
    /// - Parameter wrappedValue: A function that creates a new handler.
    public init(wrappedValue: @autoclosure @escaping () -> Handler) {
        self.make = wrappedValue
    }

    public func anyActuator<Environment: EnvironmentSnapshot>(mapsTo keyPath: PartialKeyPath<Environment>)
        -> (PartialKeyPath<Environment>, AnyActuatorHandler)
    {
        let actualKeyPath = unsafeDowncast(
            keyPath,
            to: WritableKeyPath<Environment, EnvironmentProtocolWriteOnlyProperty<Handler.Value>>.self
        )
        let valuePath = actualKeyPath.appending(path: \.wrappedValue)
        return (valuePath, AnyActuatorHandler(wrappedValue, mapsTo: valuePath))
    }

}
