struct Schedule: Hashable {

    var cycleLength: Duration {
        threads.map {
            guard let last = $0.sections.last else {
                fatalError("Schedule must contain at least one section")
            }
            guard let lastTimeslot = last.timeslots.last else {
                fatalError("Schedule snapshot section must contain at least one timeslot")
            }
            return lastTimeslot.startingTime + lastTimeslot.duration
        }.max() ?? .zero
    }

    var allTimeslots: [Timeslot] {
        threads.flatMap { $0.sections.flatMap(\.timeslots) }
    }

    var threads: [ScheduleThread]

    func isValid(forPool pool: ExecutablePool) -> Bool {
        if nil != threads.first(where: { !$0.isValid }) {
            return false
        }
        let sections = threads.flatMap(\.sections)
        var schedules: [String: ScheduleThread] = [:]
        for section in sections {
            let executables = Set(section.timeslots.flatMap(\.executables)).map { pool.executable($0) }
            let dependencies = Set(executables.flatMap { executable -> [String] in
                let handlers = executable.executable.handlers
                return handlers.externalVariables.map(\.id)
                    + handlers.globalVariables.map(\.id)
                    + handlers.sensors.map(\.id)
                    + handlers.actuators.map(\.id)
            })
            for dependency in dependencies {
                var schedule = schedules[dependency] ?? ScheduleThread(sections: [])
                if schedule.willOverlap(section) {
                    return false
                }
                schedule.add(section)
                schedules[dependency] = schedule
            }
        }
        return true
    }

}
