public class AnySchedulerContext {

    public internal(set) var fsmID: Int

    public internal(set) var fsmName: String

    public var duration: Duration

    public internal(set) var transitioned: Bool

    internal var startTime: ContinuousClock.Instant = .now

    public init(fsmID: Int, fsmName: String, duration: Duration = .zero, transitioned: Bool = true) {
        self.fsmID = fsmID
        self.fsmName = fsmName
        self.duration = duration
        self.transitioned = transitioned
    }

}
