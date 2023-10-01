/// Provides a means of recording if an action occurs.
final class Recorder {

    /// Indicates whether the action occured.
    var read: Bool

    /// Create a new Recorder.
    ///
    /// - Parameter read: The initial value of `read` that indicates whether the
    /// action occured.
    init(read: Bool = false) {
        self.read = read
    }

}
