public protocol ScheduleProtocol {

    associatedtype Arrangement: ArrangementProtocol

    var arrangement: Arrangement { get }

    var groups: [GroupInformation] { get }

}

public extension ScheduleProtocol {

    func main() throws {
        var scheduler = RoundRobinScheduler(schedule: self, parameters: [:])
        while !scheduler.shouldTerminate {
            scheduler.cycle()
        }
    }

}

public extension ScheduleProtocol where Self.Arrangement: EmptyInitialisable {

    var arrangement: Arrangement { Arrangement() }

}
