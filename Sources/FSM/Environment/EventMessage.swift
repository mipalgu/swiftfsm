/// Provides an interface for associating values with an event counter.
///
/// By doing so, this allows the differentiation between two events that have
/// the same value, but different event counters.
public struct EventMessage<Counter: FixedWidthInteger, Value: DataStructure>: DataStructure
where Counter: DataStructure {

    /// The event counter associated with this message.
    public var eventCounter: Counter = .zero

    /// The value associated with this message.
    public var value: Value

    /// The designated initializer.
    ///
    /// - Parameter eventCounter: The event counter associated with this
    /// message.
    ///
    /// - Parameter value: The value associated with this message.
    public init(eventCounter: Counter = .zero, value: Value) {
        self.eventCounter = eventCounter
        self.value = value
    }

}
