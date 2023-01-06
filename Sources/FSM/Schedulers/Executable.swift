public protocol Executable {

    func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: AnyObject)

    func saveSnapshot(data: AnyObject)

    func takeSnapshot(data: AnyObject)

}
