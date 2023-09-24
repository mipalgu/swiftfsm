public protocol SchedulerContextProtocol {

    var fsmID: Int { get }

    var fsmName: String { get }

    var duration: Duration { get set }

    var transitioned: Bool { get }

    var startTime: ContinuousClock.Instant { get set }

}
