/// Provides a means of recording if an action occurs.
final class Recorder {

    /// Indicates whether the action occured.
    var read: Bool

    var forcingValue: Sendable

    var writtenValue: Sendable?

    var cloned: Recorder {
        Recorder(read: read, forcingValue: forcingValue, writtenValue: writtenValue)
    }

    /// Create a new Recorder.
    ///
    /// - Parameter read: The initial value of `read` that indicates whether the
    /// action occured.
    init(read: Bool = false, forcingValue: Sendable, writtenValue: Sendable? = nil) {
        self.read = read
        self.forcingValue = forcingValue
        self.writtenValue = writtenValue
    }

    func resetRead() {
        read = false
    }

    func resetWrite() {
        writtenValue = nil
    }

    func reset() {
        resetRead()
        resetWrite()
    }

}
