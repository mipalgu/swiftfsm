import FSM

/// Represents the metadata associated with a timeslot.
struct Timeslot: Hashable {

    /// The set of id's of executables that are permitted to execute within this
    /// timeslot.
    var executables: Set<Int>

    /// The call chain of this timeslot.
    ///
    /// The call chain represents the status of the stack for the this timeslot.
    var callChain: CallChain

    /// The set of dependencies that the fsms within this timeslot have to other
    /// fsms within other timeslots.
    var externalDependencies: [ExecutableDependency]

    /// The starting time of the timeslot as a relative offset
    /// from the beginning of the schedule cycle.
    var startingTime: Duration

    /// The amount of time it takes to execute this timeslot.
    var duration: Duration

    /// The number of cycles that have already been executed for this timeslot.
    var cyclesExecuted: UInt

    /// Represent the starting time and duration as a range in nanoseconds.
    var timeRange: ClosedRange<UInt> {
        startingTime.timeValue...(startingTime.timeValue + duration.timeValue)
    }

    /// Computes the amount of time that must elapse after executing this
    /// timeslot before reaching the relative offset `time` within
    /// the schedule.
    ///
    /// - Parameter time: A point within the schedule cycle.
    ///
    /// - Parameter cycleLength: The total amount of time it
    /// takes to execute a single schedule cycle.
    ///
    /// - Returns: The amount of time that must elapse after
    /// executing this timeslot before reaching `time` within the schedule
    /// cycle.
    func afterExecutingTimeUntil(time: Duration, cycleLength: Duration) -> Duration {
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
    /// - Parameter cycleLength: The total amount of time it
    /// takes to execute a single schedule cycle.
    ///
    /// - Returns: The amount of time that must elapse after
    /// executing this timeslot before reaching `timeslot` within the schedule
    /// cycle.
    func afterExecutingTimeUntil(timeslot: Timeslot, cycleLength: Duration) -> Duration {
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
