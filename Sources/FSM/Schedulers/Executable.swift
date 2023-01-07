public protocol Executable {

    func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, context: AnySchedulerContext)

    func saveSnapshot(context: AnySchedulerContext)

    func takeSnapshot(context: AnySchedulerContext)

}
