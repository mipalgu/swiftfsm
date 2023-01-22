public protocol Executable {

    func next(context: AnySchedulerContext)

    func saveSnapshot(context: AnySchedulerContext)

    func takeSnapshot(context: AnySchedulerContext)

}
