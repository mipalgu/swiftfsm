public protocol App {

    associatedtype Schedule: ScheduleModel

}

public extension App {

    static func main() throws {
        let schedule = Schedule()
        var scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:])
        while !scheduler.shouldTerminate {
            scheduler.cycle()
        }
    }

}
