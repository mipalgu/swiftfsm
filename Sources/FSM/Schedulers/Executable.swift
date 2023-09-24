public protocol Executable {

    func isFinished(context: AnySchedulerContext) -> Bool

    func isSuspended(context: AnySchedulerContext) -> Bool

    func next(context: AnySchedulerContext)

    func saveSnapshot(context: AnySchedulerContext)

    func setup(context: AnySchedulerContext)

    func takeSnapshot(context: AnySchedulerContext)

    func tearDown(context: AnySchedulerContext)

}
