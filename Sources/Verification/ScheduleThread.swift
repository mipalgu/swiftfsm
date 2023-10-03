/// Represents a single sequential static schedule composed of
/// `SnapshotSection`s.
public struct ScheduleThread: Hashable {

    /// All `SnapshotSection`s making up the sequential schedule.
    var sections: [SnapshotSection]

    var externalDependencies: Set<ExecutableDependency> {
        Set(sections.flatMap(\.externalDependencies))
    }

    public init(sections: [SnapshotSection]) {
        self.sections = sections
    }

    var isValid: Bool {
        if nil != sections.first(where: { !$0.isValid }) {
            return false
        }
        let timeslots = sections.flatMap { $0.timeslots }
        for i in 0..<timeslots.count {
            for j in (i + 1)..<timeslots.count {
                if timeslots[i].overlaps(with: timeslots[j]) {
                    return false
                }
            }
        }
        return true
    }

    mutating func add(_ section: SnapshotSection) {
        sections.append(section)
    }

    mutating func merge(_ other: ScheduleThread) {
        for section in other.sections {
            if let sameIndex = self.sections.firstIndex(where: { $0.timeRange == section.timeRange }) {
                self.sections[sameIndex].timeslots.append(contentsOf: section.timeslots)
            } else {
                self.sections.append(section)
            }
        }
        self.sections.sort { $0.startingTime <= $1.startingTime }
    }

    func sharesDependencies(with other: ScheduleThread) -> Bool {
        !externalDependencies.isDisjoint(with: other.externalDependencies)
    }

    func willOverlap(_ section: SnapshotSection) -> Bool {
        nil != sections.first { $0.overlaps(with: section) }
    }

    func willOverlapUnlessSame(_ other: ScheduleThread) -> Bool {
        if self.sections.isEmpty {
            return false
        }
        for i in 0..<(sections.count - 1) {
            if nil != sections[(i + 1)..<sections.count].first(where: {
                $0.overlapsUnlessSame(with: sections[i])
            }) {
                return true
            }
        }
        return false
    }

    func verificationMap(delegates: Set<Int>) -> VerificationMap {
        let steps =
            sections
            .sorted { $0.startingTime < $1.startingTime }
            .flatMap { section -> [VerificationMap.Step] in
                if section.timeslots.count == 1 && section.timeRange == section.timeslots[0].timeRange {
                    return [
                        VerificationMap.Step(
                            time: section.startingTime,
                            step: .takeSnapshotAndStartTimeslot(timeslot: section.timeslots[0])
                        ),
                        VerificationMap.Step(
                            time: section.startingTime + section.duration,
                            step: .executeAndSaveSnapshot(timeslot: section.timeslots[0])
                        )
                    ]
                }
                let startStep = VerificationMap.Step(
                    time: section.startingTime, step:
                    .takeSnapshot(timeslots: Set(section.timeslots))
                )
                let fsmSteps = section.timeslots.flatMap {
                    [
                        VerificationMap.Step(time: $0.startingTime, step: .startTimeslot(timeslot: $0)),
                        VerificationMap.Step(time: $0.duration, step: .execute(timeslot: $0))
                    ]
                }
                let endStep = VerificationMap.Step(
                    time: section.startingTime,
                    step: .saveSnapshot(timeslots: Set(section.timeslots))
                )
                return [startStep] + fsmSteps + [endStep]
            }
        return VerificationMap(steps: steps, delegates: delegates)
    }

}
