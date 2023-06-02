import FSM

public protocol ScheduleProtocol {

    associatedtype Arrangement: ArrangementProtocol

    var arrangement: Arrangement { get }

    var groups: [GroupInformation] { get }

}

extension ScheduleProtocol {

    public func main() throws {
        var scheduler = RoundRobinScheduler(schedule: self, parameters: [:])
        while !scheduler.shouldTerminate {
            scheduler.cycle()
        }
    }

}

extension ScheduleProtocol where Self.Arrangement: EmptyInitialisable {

    public var arrangement: Arrangement { Arrangement() }

}
