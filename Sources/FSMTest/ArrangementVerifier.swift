import FSM
import Model
import Verification

public final class ArrangementVerifier<Arrangement: ArrangementProtocol> {

    private let arrangement: Arrangement

    public init(arrangement: Arrangement) {
        self.arrangement = arrangement
    }

    public func generateKripkeStructures<Schedule: ScheduleProtocol>(
        forSchedule schedule: Schedule,
        formats: Set<View>,
        usingClocks: Bool
    ) throws where Schedule.Arrangement == Arrangement {
        let isolator = ScheduleIsolator(arrangement: arrangement, schedule: schedule)
        try isolator.generateKripkeStructures(formats: formats, usingClocks: usingClocks)
    }

    public func generateKripkeStructure(formats: Set<View>, usingClocks: Bool) throws {
        try generateKripkeStructures(
            forSchedule: arrangement.defaultSchedule,
            formats: formats,
            usingClocks: usingClocks
        )
    }

}
