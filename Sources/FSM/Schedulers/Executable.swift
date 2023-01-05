public protocol Executable {

    mutating func next<Scheduler: SchedulerProtocol>(scheduler: Scheduler, data: inout Sendable)

    mutating func saveSnapshot(data: inout Sendable)

    mutating func takeSnapshot(data: inout Sendable)

}
