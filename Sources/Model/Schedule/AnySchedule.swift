/// A type-erased `ScheduleProtocol` that contains information regarding when and in what order to execute finite state machines within an
/// `ArrangementProtocol`.
///
/// The schedule is composed of groups that represent separate threads of execution. Each group contains a sequence of slots that are executed
/// sequentially, and in order.
public struct AnySchedule<Arrangement: ArrangementProtocol>: ScheduleProtocol {

    /// The arrangement that contains the finite state machines that comprise this schedule.
    public var arrangement: Arrangement

    /// All groups that comprise this schedule.
    ///
    /// Each group represents a single thread of execution, where each thread executes a sequence of finite state machines sequentially.
    public var groups: [GroupInformation]

    /// Create a schedule containing a single group comprised of the given slots.
    ///
    /// - Parameter arrangement: The arrangement that contains the finite state machines that are to comprise this schedule.
    ///
    /// - Parameter slots: The slots that will be converted to a single `GroupInformation`.
    public init(arrangement: Arrangement, slots: [SlotInformation]) {
        self.init(arrangement: arrangement, groups: [GroupInformation(slots: slots)])
    }

    /// Create a new AnySchedule.
    ///
    /// - Parameter arrangement: The arrangement that contains the finite state machines that are to comprise this schedule.
    ///
    /// - Parameter slots: The groups that contains the slots to be executed.
    public init(arrangement: Arrangement, groups: [GroupInformation]) {
        self.arrangement = arrangement
        self.groups = groups
    }

}
