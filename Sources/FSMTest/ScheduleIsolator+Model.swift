import FSM
import Model
import Verification

extension ScheduleIsolator {

    init<Arrangement: ArrangementProtocol, Schedule: ScheduleProtocol>(
        arrangement: Arrangement,
        schedule: Schedule
    ) where Schedule.Arrangement == Arrangement {
        let verificationSchedule = Verification.Schedule(threads: schedule.groups.map {
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
            arrangement.normalisedFSMs.map { machine in
                let info = machine.projectedValue
                let (executable, contextFactory) = machine.make(arrangement)
                let initialContext = contextFactory(nil)
                return (info, (initialContext, ExecutableType.controllable(executable)))
            }
        self.init(schedule: verificationSchedule, pool: ExecutablePool(executables: elements))
    }

}
