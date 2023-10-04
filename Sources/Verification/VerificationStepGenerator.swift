import FSM

struct VerificationStepGenerator {

    func takeSnapshot(forFsms contexts: [VerificationContext], in pool: ExecutablePool) -> [ExecutablePool] {
        if contexts.isEmpty {
            return [pool.cloned]
        }
        let snapshotPool = pool.cloned
        let snapshotSensors = contexts.map { context in
            context.resetReads()
            let executable = snapshotPool.executable(context.information.id).executable
            let handlers = executable.handlers
            handlers.actuators = context.recorderHandlers.actuators
            handlers.externalVariables = context.recorderHandlers.externalVariables
            handlers.globalVariables = context.recorderHandlers.globalVariables
            handlers.sensors = context.recorderHandlers.sensors
            let fsmContext = snapshotPool.context(context.information.id)
            executable.takeSnapshot(context: fsmContext)
            var allSensors: [EnvironmentIndex: any SensorHandler] = [:]
            allSensors.reserveCapacity(
                handlers.externalVariables.count + handlers.globalVariables.count + handlers.sensors.count
            )
            handlers.externalVariables.indices.forEach {
                guard context.externalVariableRecorders[$0].read else {
                    return
                }
                allSensors[.externalVariable($0)] = context.recorderHandlers.externalVariables[$0].base
            }
            handlers.globalVariables.indices.forEach {
                guard context.globalVariableRecorders[$0].read else {
                    return
                }
                allSensors[.globalVariable($0)] = context.recorderHandlers.globalVariables[$0].base
            }
            handlers.sensors.indices.forEach {
                guard context.sensorRecorders[$0].read else {
                    return
                }
                allSensors[.sensor($0)] = context.recorderHandlers.sensors[$0].base
            }
            return allSensors
        }
        let combinations = try! Combinations(sensors: snapshotSensors)
        return combinations.map { combination in
            let pool = pool.cloned
            contexts.enumerated().forEach {
                let fsmContext = pool.context($1.information.id)
                let executable = pool.executable($1.information.id).executable
                let snapshotSensors = combination[$0]
                for (index, value) in snapshotSensors {
                    switch index {
                    case .actuator(let index):
                        $1.actuatorRecorders[index].forcingValue = value
                        executable.handlers.actuators[index] = $1.recorderHandlers.actuators[index]
                    case .externalVariable(let index):
                        $1.externalVariableRecorders[index].forcingValue = value
                        // swiftlint:disable:next line_length
                        executable.handlers.externalVariables[index] = $1.recorderHandlers.externalVariables[index]
                    case .globalVariable(let index):
                        $1.globalVariableRecorders[index].forcingValue = value
                        // swiftlint:disable:next line_length
                        executable.handlers.globalVariables[index] = $1.recorderHandlers.globalVariables[index]
                    case .sensor(let index):
                        $1.sensorRecorders[index].forcingValue = value
                        executable.handlers.sensors[index] = $1.recorderHandlers.sensors[index]
                    }
                }
                executable.takeSnapshot(context: fsmContext)
            }
            return pool
        }
    }

    func execute(
        timeslot: Timeslot,
        // promises: [String: PromiseData],
        inPool pool: ExecutablePool
    ) -> [ConditionalRinglet] {
        // let pool = pool.cloned
        // let setPromises = pool.setPromises(promises)
        let element = pool.executables[pool.index(of: timeslot.callChain.executable)]
        let ringlets = TimeAwareRinglets(
            fsm: element.information,
            pool: pool,
            timeslot: timeslot,
            startingTime: .zero
        ).ringlets
        // setPromises.forEach { $0.apply() }
        return ringlets
    }

    func saveSnapshot(timeslot: Timeslot, inPool pool: ExecutablePool) -> ExecutablePool {
        let pool = pool.cloned
        let element = pool.executables[pool.index(of: timeslot.callChain.executable)]
        element.verificationContext.resetWrites()
        let handlers = element.executable.handlers
        let recorderHandlers = element.verificationContext.recorderHandlers
        handlers.actuators = recorderHandlers.actuators
        handlers.externalVariables = recorderHandlers.externalVariables
        handlers.globalVariables = recorderHandlers.globalVariables
        handlers.sensors = recorderHandlers.sensors
        element.executable.saveSnapshot(context: element.context)
        for actuator in element.verificationContext.actuatorRecorders {
            guard let writtenValue = actuator.writtenValue else {
                continue
            }
            actuator.forcingValue = writtenValue
        }
        for externalVariable in element.verificationContext.externalVariableRecorders {
            guard let writtenValue = externalVariable.writtenValue else {
                continue
            }
            externalVariable.forcingValue = writtenValue
        }
        for globalVariable in element.verificationContext.globalVariableRecorders {
            guard let writtenValue = globalVariable.writtenValue else {
                continue
            }
            globalVariable.forcingValue = writtenValue
        }
        // handlers.actuators = recorderHandlers.actuators
        // handlers.externalVariables = recorderHandlers.externalVariables
        // handlers.globalVariables = recorderHandlers.globalVariables
        // handlers.sensors = recorderHandlers.sensors
        return pool
    }

}
