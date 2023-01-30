public protocol ArrangementProtocol {

    var fsms: [Machine] { get }

}

public extension ArrangementProtocol {

    typealias Machine = FSMProperty<Self>

    var defaultSchedule: AnySchedule<Self> {
        let slots = self.fsms.map {
            SlotInformation(fsm: $0.projectedValue, timing: nil)
        }
        return AnySchedule(arrangement: self, slots: slots)
    }

    func main() throws {
        try defaultSchedule.main()
    }

}
