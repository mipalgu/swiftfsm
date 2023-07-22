public class AnySchedulerContext {

    public internal(set) var fsmID: Int

    public internal(set) var duration: Duration

    public internal(set) var transitioned: Bool

    internal var startTime: ContinuousClock.Instant = .now

    public init(fsmID: Int, duration: Duration = .zero, transitioned: Bool = true) {
        self.fsmID = fsmID
        self.duration = duration
        self.transitioned = transitioned
    }

}
