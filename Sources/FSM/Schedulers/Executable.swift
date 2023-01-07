public protocol Executable {

    func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, context: AnyObject)

    func saveSnapshot(context: AnyObject)

    func takeSnapshot(context: AnyObject)

}
