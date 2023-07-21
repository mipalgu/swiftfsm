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
