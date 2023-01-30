public protocol ArrangementModel: EmptyInitialisable {

    var fsms: [Machine] { get }

}

public extension ArrangementModel {

    typealias Machine = FSMProperty<Self>

    var fsms: [Machine] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? Machine
        }
    }

}

public extension ArrangementModel {

    static func main() {
        let arrangement = Self()
        let slots = arrangement.fsms.map {
            SlotInformation(fsm: $0.projectedValue, timing: nil)
        }
        let schedule = AnySchedule(arrangement: Self.self, slots:slots)
        var scheduler = RoundRobinScheduler(schedule: schedule, parameters: [:])
        while !scheduler.shouldTerminate {
            scheduler.cycle()
        }
    }

}
