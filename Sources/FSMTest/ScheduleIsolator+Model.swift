import FSM
import Model
import Verification

extension ScheduleIsolator {

    init<Arrangement: ArrangementProtocol, Schedule: ScheduleProtocol>(
        arrangement: Arrangement,
        schedule: Schedule
    ) where Schedule.Arrangement == Arrangement {
        var latestID = 0
        var ids: [Int: Int] = [:]
        func id(for fsm: Int) -> Int {
            if let id = ids[fsm] {
                return id
            } else {
                let foundID = latestID
                latestID += 1
                ids[fsm] = foundID
                return foundID
            }
        }
        let normalisedGroups: [GroupInformation] = schedule.groups.map {
            GroupInformation(slots: $0.slots.map {
                let newInfo = FSMInformation(
                    id: id(for: $0.fsm.id),
                    name: $0.fsm.name,
                    dependencies: $0.fsm.dependencies
                )
                if let startTime = $0.startTime, let duration = $0.duration {
                    return SlotInformation(fsm: newInfo, timing: (startTime: startTime, duration: duration))
                } else {
                    return SlotInformation(fsm: newInfo, timing: nil)
                }
            })
        }
        let verificationSchedule = Verification.Schedule(threads: normalisedGroups.map {
            ScheduleThread(
                sections: $0.slots.map {
                    SnapshotSection(
                        timeslots: [
                            Timeslot(
                                executables: [$0.fsm.id],
                                callChain: CallChain(root: $0.fsm.id, calls: []),
                                externalDependencies: [],
                                startingTime: $0.startTime.map { Duration.nanoseconds($0) } ?? .zero,
                                duration: $0.duration.map { Duration.nanoseconds($0) } ?? .zero,
                                cyclesExecuted: 0
                            )
                        ]
                    )
                }
            )
        })
        let elements: [(FSMInformation, (AnySchedulerContext, ExecutableType))] =
            arrangement.fsms.map { machine in
                let oldInfo = machine.projectedValue
                let info = FSMInformation(
                    id: id(for: oldInfo.id),
                    name: oldInfo.name,
                    dependencies: oldInfo.dependencies
                )
                let (executable, contextFactory) = machine.make(arrangement)
                let initialContext = contextFactory(nil)
                return (info, (initialContext, ExecutableType.controllable(executable)))
            }
        self.init(schedule: verificationSchedule, pool: ExecutablePool(executables: elements))
    }

}
