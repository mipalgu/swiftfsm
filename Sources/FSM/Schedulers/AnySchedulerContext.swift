public class AnySchedulerContext: CustomReflectable {

    public internal(set) var fsmID: Int

    public internal(set) var fsmName: String

    public var duration: Duration

    public internal(set) var transitioned: Bool

    internal var startTime: ContinuousClock.Instant = .now

    public var afterCalls: [Duration] = []

    public var cloned: AnySchedulerContext {
        let clone = AnySchedulerContext(
            fsmID: fsmID,
            fsmName: fsmName,
            handlers: handlers,
            duration: duration,
            transitioned: transitioned
        )
        clone.startTime = startTime
        return clone
    }

    public var customMirror: Mirror {
        Mirror(
            self,
            children: [],
            displayStyle: .class,
            ancestorRepresentation: .generated
        )
    }

    public var handlers: Handlers

    public init(fsmID: Int, fsmName: String, handlers: Handlers, duration: Duration = .zero, transitioned: Bool = true) {
        self.fsmID = fsmID
        self.fsmName = fsmName
        self.handlers = handlers
        self.duration = duration
        self.transitioned = transitioned
    }

}
