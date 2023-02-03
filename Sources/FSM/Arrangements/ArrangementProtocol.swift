public protocol ArrangementProtocol {

    var fsms: [Machine] { get }

}

extension ArrangementProtocol {

    public typealias Machine = FSMProperty<Self>

    public var defaultSchedule: AnySchedule<Self> {
        let slots = self.fsms.map {
            SlotInformation(fsm: $0.projectedValue, timing: nil)
        }
        return AnySchedule(arrangement: self, slots: slots)
    }

    public func main() throws {
        try defaultSchedule.main()
    }

}
