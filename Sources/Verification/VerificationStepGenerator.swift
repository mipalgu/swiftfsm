import FSM

struct VerificationStepGenerator {

    func takeSnapshot(forFsms contexts: [VerificationContext], in pool: ExecutablePool) -> [ExecutablePool] {
        if contexts.isEmpty {
            return [pool.cloned]
        }
        let snapshotPool = pool.cloned
        let snapshotSensors = contexts.map { context in
            context.reset()
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

    // func execute<Gateway: ModifiableFSMGateway, Timer: Clock>(
    //     timeslot: Timeslot,
    //     promises: [String: PromiseData],
    //     inPool pool: FSMPool,
    //     gateway: Gateway,
    //     timer: Timer
    // ) -> [ConditionalRinglet] where Gateway: NewVerifiableGateway {
    //     let pool = pool.cloned
    //     let setPromises = pool.setPromises(promises)
    //     gateway.pool = pool.cloned
    //     let ringlets = TimeAwareRinglets(
    //         fsm: timeslot.callChain.fsm(fromPool: pool),
    //         timeslot: timeslot,
    //         gateway: gateway,
    //         timer: timer,
    //         startingTime: 0
    //     ).ringlets
    //     setPromises.forEach { $0.apply() }
    //     return ringlets
    // }

}
