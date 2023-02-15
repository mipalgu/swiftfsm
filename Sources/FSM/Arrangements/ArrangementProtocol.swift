/// An arrangement that is a collection of `Machine`s.
/// 
/// An arrangement defines a collection of finite state machines, modelled as
/// `Machine`s, that are to be executed within a schedule. By conforming to this
/// protocol, types must define, not only the finite state machines that
/// comprise this arrangement, but must also define the dependencies between
/// finite state machines.
/// 
/// One generally conforms to `ArrangementModel` instead of this protocol, as
/// `ArrangementModel` allows one to define finite state machines as separate
/// properties of the arrangement, and automatically computes the value of
/// `fsms`.
/// 
/// - SeeAlso: `ScheduleProtocol`.
/// - SeeAlso: `ArrangementModel`.
public protocol ArrangementProtocol {

    /// The finite state machines that comprise this arrangement.
    var fsms: [Machine] { get }

}

extension ArrangementProtocol {

    /// A type of a single finite state machine that comprises this arrangement.
    public typealias Machine = FSMProperty<Self>

    /// A schedule that executes the finite state machines in this arrangement
    /// in round-robin, in the order in which they are defined.
    public var defaultSchedule: AnySchedule<Self> {
        let slots = self.fsms.map {
            SlotInformation(fsm: $0.projectedValue, timing: nil)
        }
        return AnySchedule(arrangement: self, slots: slots)
    }

    /// Execute the default schedule.
    public func main() throws {
        try defaultSchedule.main()
    }

}
