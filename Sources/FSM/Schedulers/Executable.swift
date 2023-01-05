public protocol Executable {

    func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: inout Sendable)

    func saveSnapshot(data: inout Sendable)

    func takeSnapshot(data: inout Sendable)

}
