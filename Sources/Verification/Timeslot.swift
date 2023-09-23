import FSM

/// Represents the metadata associated with a timeslot.
struct Timeslot: DataStructure {

    /// The set of id's of executables that are permitted to execute within this
    /// timeslot.
    var executables: Set<Int>

    // var callChain: CallChain

    // var externalDependencies: [ShallowDependency]

    /// The starting time of the timeslot as a relative offset (in nanoseconds)
    /// from the beginning of the schedule cycle.
    var startingTime: UInt

    /// The amount of time it takes to execute this timeslot in nanoseconds.
    var duration: UInt

    /// The number of cycles that have already been executed for this timeslot.
    var cyclesExecuted: UInt

    /// Represent the starting time and duration as a range in nanoseconds.
    var timeRange: ClosedRange<UInt> {
        startingTime...(startingTime + duration)
    }

    /// Computes the amount of time that must elapse after executing this
    /// timeslot before reaching the relative nanosecond offset `time` within
    /// the schedule.
    ///
    /// - Parameter time: A point within the schedule cycle in nanoseconds.
    ///
    /// - Parameter cycleLength: The total amount of time (in nanoseconds) it
    /// takes to execute a single schedule cycle.
    ///
    /// - Returns: The amount fo time (in nanoseconds) that must elapse after
    /// executing this timeslot before reaching `time` within the schedule
    /// cycle.
    func afterExecutingTimeUntil(time: UInt, cycleLength: UInt) -> UInt {
        let currentTime = startingTime + duration
        if time >= currentTime {
            return time - currentTime
        } else {
            return (cycleLength - currentTime) + time
        }
    }

    /// Computes the amount of time that must elapse after executing this
    /// timeslot before reaching the given timeslot within the schedule.
    ///
    /// - Parameter timeslot: The point within the schedule cycle we are
    /// measuring against.
    ///
    /// - Parameter cycleLength: The total amount of time (in nanoseconds) it
    /// takes to execute a single schedule cycle.
    ///
    /// - Returns: The amount fo time (in nanoseconds) that must elapse after
    /// executing this timeslot before reaching `timeslot` within the schedule
    /// cycle.
    func afterExecutingTimeUntil(timeslot: Timeslot, cycleLength: UInt) -> UInt {
        afterExecutingTimeUntil(time: timeslot.startingTime, cycleLength: cycleLength)
    }

    /// Does this timeslot overlap (i.e. can this timeslot execute at the same
    /// time) with the given timeslot?
    ///
    /// - Parameter other: The timeslot that we are checking whether it is
    /// possible for this timeslot to overlap with.
    ///
    /// - Returns: Whether this timeslot overlaps with `other`.
    func overlaps(with other: Timeslot) -> Bool {
        self.timeRange.overlaps(other.timeRange)
    }

}
