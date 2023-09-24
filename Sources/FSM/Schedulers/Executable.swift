public protocol Executable {

    func isFinished(context: UnsafePointer<SchedulerContextProtocol>) -> Bool

    func isSuspended(context: UnsafePointer<SchedulerContextProtocol>) -> Bool

    func next(context: UnsafeMutablePointer<SchedulerContextProtocol>)

    func saveSnapshot(context: UnsafeMutablePointer<SchedulerContextProtocol>)

    func takeSnapshot(context: UnsafeMutablePointer<SchedulerContextProtocol>)

}
