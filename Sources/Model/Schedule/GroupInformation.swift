import FSM

/// A data structure that contains metadata relating to a group that executes within a schedule.
///
/// A group within a schedule represents a single thread of execution. This single thread of execution executes a sequence of finite state machines
/// sequentially, and in order. This data structure is responsible for defining the sequence of slots, where each slot contains metadata about the finite
/// state machine that occupies it, that comprise the group.
public struct GroupInformation: DataStructure {

    /// The slots that belong to this group.
    ///
    /// Each slot contains metadata associated with a single fintie state machine, essentially providing information about when to execute a ringlet
    /// for the finite state machine within the schedule.
    public let slots: [SlotInformation]

    /// The amount of time it takes to execute this group.
    ///
    /// When using a non-time-trigggered schedule, this value is nil. When using a time-triggered schedule, this value should be at least as big as
    /// the total duration of executing all slots within the schedule. This value can be bigger than the total duration of the slots, by doing so, this
    /// implies that the group should sleep until the final duration time has expired after executing the final slot within the `slots` array.
    public let duration: UInt?

    /// Create a new GroupInformation and mannualy override the default duration time to allow a greater duration time than the total duration of
    /// executing `slots`.
    ///
    /// - Parameter slots: The slots that comprise this group.
    ///
    /// - Parameter duration: Manually set a duration value that overrides the default calculated duration that is derived from the total
    /// execution time for executing all slots sequentially.
    ///
    /// - Warning: The given duration should at least be greater than or equal to the total duration of executing `slots`.
    public init(slots: [SlotInformation], duration: UInt?) {
        self.slots = slots
        self.duration = duration
    }

    /// Create a new GroupInformation, calculating the value of `duration`.
    ///
    /// If the slots contain start and end times, then this initialiser calculates the value of `duration` to be the gretest end time of all provided
    /// slots. If the slots do not contain a start time and end time, then `duration` will be set to nil.
    ///
    /// - Parameter slots: The slots that comprise this group.
    ///
    /// - SeeAlso: `SlotInformation`.
    public init(slots: [SlotInformation]) {
        self.slots = slots
        let endSlots = slots.compactMap(\.endTime)
        guard endSlots.count == slots.count else {
            self.duration = nil
            return
        }
        self.duration = endSlots.max()
    }

}
