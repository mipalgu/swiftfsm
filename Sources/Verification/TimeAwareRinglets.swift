import FSM
import KripkeStructure

struct TimeAwareRinglets {

    var ringlets: [ConditionalRinglet]

    init(fsm information: FSMInformation, pool: ExecutablePool, timeslot: Timeslot, startingTime: Duration) {
        var lastTime: Duration
        var smallerTimes: SortedCollection<Duration> = []
        var times: SortedCollection<Duration> = []
        var ringlets: [ConditionalRinglet] = []
        var indexes: [RingletResult: Int] = [:]
        let initialContext = pool.context(information.id)
        var pool = pool.cloned
        let executable = pool.executable(information.id)
        func createCondition(runningAt time: Timing, result: RingletResult) -> Constraint<UInt> {
            let condition: Constraint<UInt>
            if let index = indexes[result] {
                condition = .or(lhs: ringlets[index].condition, rhs: time.condition).reduced
            } else {
                condition = time.condition.reduced
            }
            let finalCondition: Constraint<UInt>
            if let big = times.first {
                finalCondition = .and(lhs: condition, rhs: .lessThanEqual(value: big.timeValue)).reduced
            } else {
                finalCondition = condition
            }
            return finalCondition
        }
        func calculate(time: Timing) {
            let clone = initialContext.cloned
            clone.duration = time.durationValue
            pool.insert(executable, context: clone, information: information)
            let ringlet = Ringlet(pool: pool, timeslot: timeslot)
            for newTime in ringlet.afterCalls {
                if newTime <= lastTime, !smallerTimes.contains(newTime) {
                    smallerTimes.insert(newTime)
                } else if newTime > lastTime, !times.contains(newTime) {
                    times.insert(newTime)
                }
            }
            let result = RingletResult(ringlet: ringlet)
            let condition = createCondition(runningAt: time, result: result)
            if let index = indexes[result] {
                ringlets[index].condition = condition.reduced
            } else {
                indexes[result] = ringlets.count
                ringlets.append(ConditionalRinglet(ringlet: ringlet, condition: condition.reduced))
            }
        }
        if startingTime == .zero {
            lastTime = .zero
            calculate(time: .beforeOrEqual(startingTime))
            if let firstAfter = times.first {
                ringlets[0].condition = .lessThanEqual(value: firstAfter.timeValue)
            }
        } else {
            lastTime = startingTime - Duration.nanoseconds(1)
            calculate(time: .after(lastTime))
            if let lastSmall = smallerTimes.last, let firstBig = times.first {
                ringlets[0].condition = .and(
                    lhs: .greaterThan(value: lastSmall.timeValue),
                    rhs: .lessThanEqual(value: firstBig.timeValue)
                ).reduced
            } else if let lastSmall = smallerTimes.last {
                ringlets[0].condition = .greaterThan(value: lastSmall.timeValue)
            } else if let firstBig = times.first {
                ringlets[0].condition = .and(
                    lhs: .greaterThan(value: lastTime.timeValue),
                    rhs: .lessThanEqual(value: firstBig.timeValue)
                ).reduced
            } else {
                ringlets[0].condition = .greaterThan(value: lastTime.timeValue)
            }
        }
        while !times.isEmpty {
            lastTime = times.remove(at: times.startIndex)
            calculate(time: .after(lastTime))
        }
        self.init(ringlets: ringlets)
    }

    init(ringlets: [ConditionalRinglet]) {
        self.ringlets = ringlets
    }

}
