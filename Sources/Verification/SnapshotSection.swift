import FSM

// A single section within a schedule marked by when reading from the
// environment occurs, and ended when writing to the environment occurs.
public struct SnapshotSection: Hashable {

    private(set) var startingTime: Duration

    private(set) var duration: Duration

    var timeRange: ClosedRange<UInt> {
        startingTime.timeValue...(startingTime.timeValue + duration.timeValue)
    }

    var externalDependencies: Set<ExecutableDependency> {
        Set(timeslots.flatMap(\.externalDependencies))
    }

    var executables: Set<Int> {
        Set(timeslots.flatMap(\.executables))
    }

    // The time slots that are being executed within this section of the
    // schedule.
    var timeslots: [Timeslot] {
        didSet {
            if self.timeslots.isEmpty {
                self.startingTime = .zero
                self.duration = .zero
                return
            }
            let sorted = self.timeslots.sorted { $0.startingTime <= $1.startingTime }
            guard let first = sorted.first, let last = sorted.last else {
                fatalError("Unable to calculate duration for an empty SnapshotSection")
            }
            self.startingTime = first.startingTime
            self.duration = (last.startingTime + last.duration) - first.startingTime
        }
    }

    public init(timeslots: [Timeslot]) {
        if timeslots.isEmpty {
            self.startingTime = .zero
            self.duration = .zero
            self.timeslots = timeslots
            return
        }
        let sorted = timeslots.sorted { $0.startingTime <= $1.startingTime }
        guard let first = sorted.first, let last = sorted.last else {
            fatalError("Unable to calculate duration for an empty SnapshotSection")
        }
        self.startingTime = first.startingTime
        self.duration = (last.startingTime + last.duration) - first.startingTime
        self.timeslots = sorted
    }

    init(startingTime: Duration, duration: Duration, timeslots: [Timeslot]) {
        self.startingTime = startingTime
        self.duration = duration
        self.timeslots = timeslots
    }

    var isValid: Bool {
        if timeslots.isEmpty {
            return false
        }
        for i in 0..<timeslots.count {
            for j in (i + 1)..<timeslots.count where timeslots[i].overlaps(with: timeslots[j]) {
                return false
            }
        }
        return true
    }

    func overlaps(with other: SnapshotSection) -> Bool {
        timeRange.overlaps(other.timeRange)
    }

    func overlapsUnlessSame(with other: SnapshotSection) -> Bool {
        if self.timeRange == other.timeRange {
            return false
        }
        return overlaps(with: other)
    }
    
}
